resource "aws_acm_certificate" "wordpress_cert" {
  domain_name       = "wordpressexample.com"
  validation_method = "DNS"

}