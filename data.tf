data "terraform_remote_state" "network" {
  backend = "gcs"
  config = {
    bucket = "parisaiacweu"
    prefix = "enterprise-network/weu4/default.tfstate"
  }
}