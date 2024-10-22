output "consul_ips" {
  value = [for i, instance in aws_instance.consul : i == 0 ? "${instance.public_ip}:${instance.private_ip}:" : instance.private_ip]
}

output "consul_token" {
  value = random_uuid.management_token.id
}

output "consul_ca" {
  value = tls_self_signed_cert.ca_cert.cert_pem
}
