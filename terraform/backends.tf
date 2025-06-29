terraform {
  backend "remote" {
    organization = "zlash65-ai-ml"

    workspaces {
      name = "aws-bedrock-example"
    }
  }

  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = "~> 6.0.0"
    }
  }
}
