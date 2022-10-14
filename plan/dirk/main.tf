module "vpc" {
  source = "../../modules/vpc" 
  project               = "lido-360921"
  public_subnet_1       = "10.26.2.0/24"
  private_subnet_1      = "10.26.1.0/24"
  public_subnet_2       = "10.26.4.0/24"
  private_subnet_2      = "10.26.3.0/24"
}

module "compute1" {
  source                = "../../modules/compute1"
#   network_self_link     = "${module.vpc.out_vpc_self_link}"
#   subnetwork1           = "${module.uc1.uc1_out_public_subnet_name}"
  project               = "lido-360921"
  public_subnet         = "10.26.2.0/24"
  private_subnet        = "10.26.1.0/24"
}
module "compute2" {
  source                = "../modules/compute2"
#   network_self_link     = "${module.vpc.out_vpc_self_link}"
#   subnetwork1           = "${module.ue1.ue1_out_public_subnet_name}"
  project               = "lido-360921"
  public_subnet         = "10.26.4.0/24"
  private_subnet        = "10.26.3.0/24"
}