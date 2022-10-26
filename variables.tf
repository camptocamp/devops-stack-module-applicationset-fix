#######################
## Standard variables
#######################

variable "argocd_namespace" {
  description = "Namespace used by Argo CD where the Application and AppProject resources should be created."
  type        = string
}

#######################
## Module variables
#######################

variable "name" {
  description = "Name to give the AppProject and ApplicationSet (tecnically there is also an Application where the ApplicationSet will reside that will get the same name)."
  type        = string
}

variable "generators" {
  description = "ApplicationSet generators."
  type        = any
}

variable "template" {
  description = "ApplicationSet template."
  type        = any
}

variable "project_dest_namespace" {
  description = "Allowed destination namespace in the AppProject."
  type        = string
  default     = "*"
}

variable "project_source_repos" {
  description = "List of repositories allowed to be scraped in this AppProject."
  type        = list(string)
  default     = ["*"]
}
