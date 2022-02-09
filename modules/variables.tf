#######################
## Standard variables
#######################

variable "argocd_namespace" {
  type = string
}

variable "namespace" {
  type    = string
}

variable "extra_yaml" {
  type    = list(string)
  default = []
}

#######################
## Module variables
#######################

variable "name" {
  description = "Project and application name"
  type        = string
}

variable "generators" {
  description = "ApplicationSet generators"
  type        = any
}

variable "template" {
  description = "ApplicationSet template"
  type        = any
}
