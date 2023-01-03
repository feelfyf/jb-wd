provider "google" {
  version = "~> 3.25.0"
  project = "my-gcp-project"
  region  = "us-central1"
}

resource "google_container_cluster" "cluster" {
  name     = "my-cluster"
  location = "us-central1"

  initial_node_count = 3

  node_config {
    oauth_scopes = ["https://www.googleapis.com/auth/logging.write"]
  }
}

resource "kubernetes_config_map" "deployment_config" {
  metadata {
    name = "deployment-config"
  }

  data = {
    "deployment.yaml" = file("deployment.yaml")
  }
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name = "my-app"
    labels = {
      app = "my-app"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }

      spec {
        container {
          name  = "my-app"
          image = "gcr.io/my-gcp-project/my-app:latest"

          volume_mount {
            mount_path = "/app/deployment.yaml"
            name       = "deployment-config"
            sub_path   = "deployment.yaml"
          }
        }

        volume {
          name = "deployment-config"

          config_map {
            name = kubernetes_config_map.deployment_config.metadata.0.name
          }
        }
      }
    }
  }
}
