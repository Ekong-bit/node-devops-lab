terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

# optional: if you want to add a remote backend later, we’ll insert it here.
# backend "s3" { ... }  # (we’ll keep local state for now)
