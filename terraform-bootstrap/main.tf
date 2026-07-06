provider "aws" {
  region = "eu-west-1" # Zmień na swój region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "konrad-terraform-state-2026" # NAZWA MUSI BYĆ UNIKALNA GLOBALNIE
  force_destroy = true # Pozwoli na łatwe usunięcie bucketu podczas sprzątania projektu
}

resource "aws_s3_bucket_public_access_block" "state_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}