output "landing_bucket_arn" {
  value = aws_s3_bucket.datalake["landing"].arn
}

output "landing_bucket_id" {
  value = aws_s3_bucket.datalake["landing"].id
}

output "raw_bucket_arn" {
  value = aws_s3_bucket.datalake["raw"].arn
}

output "raw_bucket_id" {
  value = aws_s3_bucket.datalake["raw"].id
}
