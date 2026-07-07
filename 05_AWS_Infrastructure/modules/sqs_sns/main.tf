# ------------------------------------------------------------------------------
# SQS & SNS for Snowpipe Event Notifications
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "snowpipe_topic" {
  name = "${var.project}-${var.environment}-snowpipe-notifications"
}

resource "aws_sqs_queue" "snowpipe_queue" {
  name = "${var.project}-${var.environment}-snowpipe-queue"

  # Dead Letter Queue configuration for failed ingest events
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.snowpipe_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "snowpipe_dlq" {
  name = "${var.project}-${var.environment}-snowpipe-dlq"
}

# Allow S3 bucket to publish to SNS
resource "aws_sns_topic_policy" "s3_publish" {
  arn = aws_sns_topic.snowpipe_topic.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.snowpipe_topic.arn
      Condition = {
        ArnLike = { "aws:SourceArn" = var.landing_bucket_arn }
      }
    }]
  })
}

# Connect S3 Event Notification to SNS
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.landing_bucket_id

  topic {
    topic_arn = aws_sns_topic.snowpipe_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}
