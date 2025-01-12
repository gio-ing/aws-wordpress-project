resource "aws_cloudfront_distribution" "wordpress" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = var.cloudfront_aliases
  #web_acl_id          = aws_waf_web_acl.wordpress.id

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    min_ttl     = 0
    default_ttl = 5 * 60
    max_ttl     = 60 * 60

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = module.s3_bucket_for_public_assets.s3_bucket_bucket_regional_domain_name
    origin_id   = module.s3_bucket_for_public_assets.s3_bucket_id

    s3_origin_config {
      origin_access_identity = "s3_bucket_oai"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {

    acm_certificate_arn      = aws_acm_certificate.wordpress_cert
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}

resource "aws_route53_zone" "main" {
  name = "wordpressexample.com"
}

resource "aws_route53_record" "www-live" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 5


  set_identifier = "live"
  records        = ["www.wordpressexample.com"]
}