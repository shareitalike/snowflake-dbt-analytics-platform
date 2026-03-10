terraform {
  backend "s3" {
    bucket       = "omniretail-tf-state-a11-xpg-1259"
    key          = "aws-landing-zone/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
