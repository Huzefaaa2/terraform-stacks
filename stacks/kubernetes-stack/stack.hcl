stack "kubernetes-stack" {
  description = "Stack that provisions an EKS control plane, managed node groups, and platform add-ons in one artifact."

  tags = {
    owner   = "platform-team"
    service = "kubernetes-platform"
  }

  deployments = {
    prod = {
      inputs = {
        region      = "us-east-1"
        environment = "prod"
      }
    }
  }

  components = {
    control_plane = {
      source = "./components/control-plane"
      inputs = {
        cluster_version = "1.30"
      }
    }

    node_pool = {
      source = "./components/node-pool"
      inputs = {
        min_size = 2
        max_size = 6
        desired_size = 3
        instance_types = ["m6i.large"]
        cluster_name   = component.control_plane.outputs.cluster_name
        subnet_ids     = component.control_plane.outputs.private_subnet_ids
        cluster_oidc   = component.control_plane.outputs.cluster_oidc
        cluster_version = component.control_plane.outputs.cluster_version
      }
      depends_on = [component.control_plane]
    }

    workloads = {
      source = "./components/workloads"
      inputs = {
        cluster_name   = component.control_plane.outputs.cluster_name
        kubeconfig     = component.control_plane.outputs.kubeconfig
        cluster_oidc   = component.control_plane.outputs.cluster_oidc
      }
      depends_on = [
        component.control_plane,
        component.node_pool,
      ]
    }
  }
}
