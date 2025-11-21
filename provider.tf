provider "oci" {
  config_file_profile = "ION-FRA"
  region              = "eu-frankfurt-1"
}

provider "oci" {
  config_file_profile = "ION-IAD"
  region              = "us-ashburn-1"
  alias = "home"
}
