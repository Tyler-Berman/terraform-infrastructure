terraform {
  backend "s3" {
    key = "terraform/tfstate.tfstate"
    bucket = "sentinel-test-bucket-2026"
    region = "us-east-2"
  }
}