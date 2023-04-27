variable "location" {
  type    = string
  default = "westeurope"
}

variable "prefix" {
  description = "team name"
  type        = string
  default     = "proja"
}

variable "stage" {
  type    = string
  default = "dev"
}

variable "name" {
  description = "project name"
  type        = string
  default     = "app"
}

variable "location_shortname" {
  type    = string
  default = "weu"
}
