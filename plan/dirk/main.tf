module "vpc" {
  source = "../../modules/vpc" 
  project               = "lido-360921"
  vpc_name              = "dirk-vpc"
  public_subnet_1       = "10.26.2.0/24"
  private_subnet_1      = "10.26.1.0/24"
  public_subnet_2       = "10.26.4.0/24"
  private_subnet_2      = "10.26.3.0/24"
}

module "compute1" {
  source                = "../../modules/compute1"
  compute_name          = "dirk1"
  compute_image         = "debian-cloud/debian-10"
  compute_size          = "e2-small"
  region_name           = "us-central1" 
  project               = "lido-360921"
  public_subnet_1       = "10.26.2.0/24"
  private_subnet_1      = "10.26.1.0/24"
  public_subnetwork     = "dirk1-public-subnet"
  private_subnetwork    = "dirk1-private-subnet"
  vpc_name              = "dirk-vpc"


}
module "compute2" {
  source                = "../../modules/compute2"
  compute_name          = "dirk2"
  compute_image         = "debian-cloud/debian-10"
  compute_size          = "e2-small" 
  region_name           = "us-east1"
  project               = "lido-360921"
  public_subnet_2       = "10.26.4.0/24"
  private_subnet_2      = "10.26.3.0/24"
  public_subnetwork     = "dirk2-public-subnet"
  private_subnetwork    = "dirk2-private-subnet"
  vpc_name              = "dirk-vpc"
}

module "compute3" {
  source                = "../../modules/compute3"
  compute_name          = "dirk3"
  compute_image         = "debian-cloud/debian-10"
  compute_size          = "e2-small" 
  region_name           = "asia-northeast1"
  project               = "lido-360921"
  public_subnet_3       = "10.26.6.0/24"
  private_subnet_3      = "10.26.5.0/24"
  public_subnetwork     = "dirk3-public-subnet"
  private_subnetwork    = "dirk3-private-subnet"
  vpc_name              = "dirk-vpc"
}

module "compute4" {
  source                = "../../modules/compute4"
  compute_name          = "dirk4"
  compute_image         = "debian-cloud/debian-10"
  compute_size          = "e2-small" 
  region_name           = "asia-south1"
  project               = "lido-360921"
  public_subnet_4       = "10.26.8.0/24"
  private_subnet_4      = "10.26.7.0/24"
  public_subnetwork     = "dirk4-public-subnet"
  private_subnetwork    = "dirk4-private-subnet"
  vpc_name              = "dirk-vpc"
}

module "compute5" {
  source                = "../../modules/compute5"
  compute_name          = "dirk5"
  compute_image         = "debian-cloud/debian-10"
  compute_size          = "e2-small" 
  region_name           = "asia-southeast1"
  project               = "lido-360921"
  public_subnet_5       = "10.26.10.0/24"
  private_subnet_5      = "10.26.9.0/24"
  public_subnetwork     = "dirk5-public-subnet"
  private_subnetwork    = "dirk5-private-subnet"
  vpc_name              = "dirk-vpc"
}