stack "multi-region-stack" {
  description = "Reference stack to roll out the same service across regions and accounts without copy/paste." 

  tags = {
    owner       = "platform-team"
    cost_center = "shared-services"
    project     = "multi-region-stack"
  }

  deployments = {
    prod_east = {
      inputs = {
        region      = "us-east-1"
        environment = "prod"
      }
    }
    prod_west = {
      inputs = {
        region      = "us-west-2"
        environment = "prod"
      }
    }
  }

  components = {
    networking = {
      source  = "./components/networking"
      inputs  = {
        cidr_block           = "10.50.0.0/16"
        public_subnet_cidrs  = ["10.50.0.0/20", "10.50.16.0/20"]
        private_subnet_cidrs = ["10.50.32.0/20", "10.50.48.0/20"]
      }
    }

    data = {
      source  = "./components/data"
      inputs = {
        table_name       = "orders"
        stream_enabled   = true
        backup_enabled   = true
        replica_regions  = ["us-west-2"]
      }
      depends_on = [
        component.networking,
      ]
    }

    app = {
      source = "./components/app-service"
      inputs = {
        desired_count = 2
        container_image = "public.ecr.aws/aws-containers/sample-app:latest"
        listener_port   = 80
        cpu             = 256
        memory          = 512
        vpc_id               = component.networking.outputs.vpc_id
        private_subnet_ids   = component.networking.outputs.private_subnet_ids
        public_subnet_ids    = component.networking.outputs.public_subnet_ids
        alb_security_group_id = component.networking.outputs.alb_security_group_id
        app_security_group_id = component.networking.outputs.app_security_group_id
        table_name            = component.data.outputs.table_name
      }
      depends_on = [
        component.networking,
        component.data,
      ]
    }

    traffic = {
      source = "./components/traffic"
      inputs = {
        zone_name    = "example.com"
        alb_dns_name = component.app.outputs.alb_dns_name
        alb_zone_id  = component.app.outputs.alb_zone_id
      }
      depends_on = [
        component.app,
      ]
    }
  }
}

provider "aws" {
  source  = "hashicorp/aws"
  version = "~> 5.59"
}
