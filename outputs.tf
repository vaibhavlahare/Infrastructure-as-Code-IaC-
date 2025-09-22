output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
