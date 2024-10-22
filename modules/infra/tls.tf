resource "tls_private_key" "ca_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}


resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_private_key.private_key_pem

  is_ca_certificate = true

  subject {
    country             = "SG"
    province            = "Singapore"
    locality            = "Singapore"
    common_name         = "Demo Root CA"
    organization        = "Demo Organization"
    organizational_unit = "Demo Organization Root Certification Authority"
  }

  validity_period_hours = 43800 //  1825 days or 5 years

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# Create private key for consul server certificate 
resource "tls_private_key" "consul_server_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# Create CSR for for consul server certificate 
resource "tls_cert_request" "consul_server_csr" {

  private_key_pem = tls_private_key.consul_server_private_key.private_key_pem

  dns_names    = ["server.dc1.consul", "localhost"]
  ip_addresses = ["127.0.0.1"]

  subject {
    country             = "SG"
    province            = "Singapore"
    locality            = "Singapore"
    common_name         = "server.dc1.consul"
    organization        = "Demo Organization"
    organizational_unit = "Development"
  }
}

# Sign Server Certificate by Private CA 
resource "tls_locally_signed_cert" "consul_server_signed_cert" {
  // CSR by the consul servers
  cert_request_pem = tls_cert_request.consul_server_csr.cert_request_pem
  // CA Private key 
  ca_private_key_pem = tls_private_key.ca_private_key.private_key_pem
  // CA certificate
  ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 43800

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}