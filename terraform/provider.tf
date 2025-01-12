# ###############################################################
# #       This section refers to the terraform providers        #
# #                                                             #
# ###############################################################

# ######################### PROVIDERS ###########################

provider "aws" {

  region  = var.aws_region
  profile = var.aws_profile

}


# ###############################################################

# ########################## BACKEND ########################## ##

terraform {
  required_version = "~> 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.5"
    }
  }
  #backend "s3" {
  #  bucket  = <your-s3-bucket>
  #  key     = "app/terraform.tfstate"
  #  region  = "eu-central-1"
  #  dynamodb_table = "example-table"
  #}
}

# ###############################################################
