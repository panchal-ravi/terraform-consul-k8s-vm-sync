locals {
  instance_type  = "t3.micro"
  instance_count = 2
}

resource "random_uuid" "management_token" {
}

data "aws_ami" "an_image" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["${var.owner}-consul-nomad-enterprise*"]
  }
}


data "cloudinit_config" "init" {
  count         = local.instance_count
  gzip          = false
  base64_encode = false

  part {
    filename     = "setup_common.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.root}/files/config/setup_common.sh", {
      consul_service = file("${path.root}/files/config/consul.service")
    })
  }

  part {
    filename     = "setup_consul.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.root}/files/config/setup_consul.sh", {
      agent_type           = count.index == 0 ? "server" : "client"
      consul_license       = file("${path.root}/files/config/consul_license.hclic")
      consul_server_config = file("${path.root}/files/config/consul_server.hcl")
      consul_client_config = templatefile("${path.root}/files/config/consul_client.hcl.tpl", {
        node_name = "consul-client-${count.index}"
      })
      consul_client_acl = templatefile("${path.root}/files/config/consul_client_acl.hcl.tpl", {
        agent_token = random_uuid.management_token.id
      })
      consul_ca_crt     = tls_self_signed_cert.ca_cert.cert_pem
      consul_server_crt = tls_locally_signed_cert.consul_server_signed_cert.cert_pem
      consul_server_key = tls_private_key.consul_server_private_key.private_key_pem
      consul_server_acl = templatefile("${path.root}/files/config/consul_server_acl.hcl.tpl", {
        management_token = random_uuid.management_token.id
      })
    })
  }
}


resource "aws_instance" "consul" {
  count                       = local.instance_count
  ami                         = data.aws_ami.an_image.id
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.this.key_name
  subnet_id                   = count.index == 0 ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]
  security_groups             = [module.bastion_sg.security_group_id, module.consul_sg.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  associate_public_ip_address = count.index == 0 ? true : false
  user_data                   = data.cloudinit_config.init[count.index].rendered

  tags = {
    Name       = "${var.deployment_id}-consul-server"
    agent_type = count.index == 0 ? "consul-server" : "consul-client"
  }

  lifecycle {
    ignore_changes = all
  }

}

resource "null_resource" "connect_ca" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOD
      curl -s -k https://${aws_instance.consul[0].public_ip}:8501/v1/connect/ca/roots | jq '.Roots[].RootCert' -r > ${path.root}/generated/connect_ca.crt
      EOD
  }
  depends_on = [time_sleep.wait_30_seconds]
}

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"
  depends_on      = [aws_instance.consul]
}
