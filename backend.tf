#Configure s3 for state 

# resource "aws_s3_bucket" "terraform_state" {
#   bucket        = "s3-state-bucket73579"
#   force_destroy = true

#   tags = {
#     Name        = "Terraform State Bucket"
#   }
# }

# resource "aws_s3_bucket_versioning" "versioning" {
#   # bucket = aws_s3_bucket.terraform_state.id
#   bucket = aws_s3_bucket.terraform_state.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "public_access" {
#   bucket = aws_s3_bucket.terraform_state.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
