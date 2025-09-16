output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "s3_bucket" {
  value = aws_s3_bucket.static.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
