# Route 53 Hosted Zone for demoapp.com
resource "aws_route53_zone" "primary" {
  name = var.domain_name

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  comment = "Private hosted zone for ${var.domain_name}"
}

# Generate TLS Private Key and Self-Signed Certificate for demoapp.com
resource "tls_private_key" "demoapp" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "demoapp" {
  private_key_pem = tls_private_key.demoapp.private_key_pem

  subject {
    common_name  = var.domain_name
    organization = "DemoApp Organization"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [
    var.domain_name,
    "*.${var.domain_name}"
  ]
}

# Import Certificate directly into AWS Certificate Manager (ACM)
# Automatically achieves ISSUED status without requiring public domain delegation
resource "aws_acm_certificate" "demoapp" {
  private_key      = tls_private_key.demoapp.private_key_pem
  certificate_body = tls_self_signed_cert.demoapp.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}
