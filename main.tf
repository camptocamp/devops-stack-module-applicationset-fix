resource "argocd_project" "this" {
  metadata {
    name      = var.name
    namespace = var.argocd_namespace
  }

  spec {
    description = "${var.name} application project"

    # Concatenate the ApplicationSet repository with the allowed repositories in order to allow the ApplicationSet 
    # to be created in this project.
    source_repos = concat(
      var.project_source_repos,
      ["https://github.com/camptocamp/devops-stack-module-applicationset.git"]
    )

    destination {
      name      = "in-cluster"
      namespace = var.project_dest_namespace
    }

    # This destination block is needed in order to allow the ApplicationSet below to be created in the namespace 
    # `argocd` while belonging to this project. This block is only needed if the user provides a namespace above
    # instead of the wildcard "*" configured by default.
    destination {
      name      = "in-cluster"
      namespace = "argocd"
    }

    orphaned_resources {
      warn = true
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

resource "argocd_application" "this" {
  metadata {
    name      = var.name
    namespace = var.argocd_namespace
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = true

  spec {
    project = argocd_project.this.metadata.0.name

    source {
      repo_url        = "https://github.com/camptocamp/devops-stack-module-applicationset.git"
      path            = "charts/applicationset"
      target_revision = "main"
      helm {
        value_files = ["values.yaml"]

        parameter {
          name  = "template"
          value = yamlencode(var.template)
        }

        parameter {
          name  = "generators"
          value = yamlencode(var.generators)
        }

        parameter {
          name  = "name"
          value = var.name
        }
      }
    }

    destination {
      name      = "in-cluster"
      namespace = var.argocd_namespace
    }

    sync_policy {
      automated = {
        allow_empty = false
        prune       = true
        self_heal   = true
      }

      retry {
        backoff = {
          duration     = ""
          max_duration = ""
        }
        limit = "0"
      }

      sync_options = [
        "CreateNamespace=true"
      ]
    }
  }
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}
