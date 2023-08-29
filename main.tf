resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

resource "argocd_repository" "private_https_repo" {
  # This count here is nothing more than a way to conditionally deploy this resource. Although there is no loop inside 
  # the resource, if the condition is true, the resource is deployed because there is exactly one iteration.
  count = (var.source_credentials_https.password != null && startswith(var.project_source_repo, "https://")) ? 1 : 0

  repo     = var.project_source_repo
  username = var.source_credentials_https.username
  password = var.source_credentials_https.password
  insecure = var.source_credentials_https.https_insecure
}

resource "argocd_repository" "private_ssh_repo" {
  # This count here is nothing more than a way to conditionally deploy this resource. Although there is no loop inside 
  # the resource, if the condition is true, the resource is deployed because there is exactly one iteration.
  count = 0 #(can(var.source_credentials_ssh_key) && startswith(var.project_source_repo, "git@")) ? 1 : 0

  repo            = var.project_source_repo
  username        = "git"
  ssh_private_key = var.source_credentials_ssh_key
}

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
      [var.project_source_repo],
      ["https://github.com/camptocamp/devops-stack-module-applicationset-fix.git"]
    )

    destination {
      name      = "in-cluster"
      server    = "https://kubernetes.default.svc"
      namespace = var.project_dest_namespace
    }

    # This destination block is needed in order to allow the ApplicationSet below to be created in the namespace 
    # `argocd` while belonging to this project. This block is only needed if the user provides a namespace above
    # instead of the wildcard "*" configured by default.
    destination {
      name      = "in-cluster"
      server    = "https://kubernetes.default.svc"
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

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = argocd_project.this.metadata.0.name

    source {
      repo_url        = "https://github.com/camptocamp/devops-stack-module-applicationset-fix.git"
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
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true"
      ]
    }
  }

  depends_on = [
    resource.null_resource.dependencies,
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}
