resource "aws_iam_server_certificate" "cert" {
  name_prefix      = "k-cert"
  certificate_body = "${file("certificate.crt")}"
  private_key      = "${file("private.pem")}"

  lifecycle {
    create_before_destroy = true
  }
}
