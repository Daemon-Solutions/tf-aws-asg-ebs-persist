# Bucket for storing Lambda zip code
resource "aws_s3_bucket" "new_bucket_lambda" {
  bucket = "s3.lambdas.${var.env}.${var.client_name}"
  acl    = "private"
  region = "${var.aws_region}"

  tags {
    Name = "s3.lambdas.${var.env}.${var.client_name}"
    env  = "${var.env}"
  }
}
