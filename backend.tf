terraform {
  backend "gcs" {
    bucket = "zemi-prod-tfstate"
    prefix = "terraform/state"
  }
}
