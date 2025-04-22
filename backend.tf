terraform {
  backend "s3" {
    bucket       = "example-state-frontend"
    key          = "med/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
