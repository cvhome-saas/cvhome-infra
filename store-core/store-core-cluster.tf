locals {
  pods_env = flatten([
    for key, value in var.pods : [
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ID_ID", value : value.id },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_NAME", value : value.name },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ENDPOINT_ENDPOINT", value : value.endpoint },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ENDPOINT_ENDPOINT-TYPE", value : value.endpointType },
      { name : "COM_ASREVO_CVHOME_PODS[${value.index}]_ORG-ID", value : value.org },
    ]
  ])
  store_core_gateway_env = [
    { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
    { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.namespace}:4318" },
    { "name" : "OTEL_SDK_DISABLED", "value" : !var.is_monitoring },
    { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT", "value" : "443" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_UAA_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_UAA_PORT", "value" : "443" },
    { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
    {
      "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
      "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
    },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE", "value" : "store-pod-1.${var.project}.lcl" },
  ]
  uaa_env = [
    { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
    { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.namespace}:4318" },
    { "name" : "OTEL_SDK_DISABLED", "value" : !var.is_monitoring },
    { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
    { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
    {      "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
      "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
    },

    { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-core-db.db_instance_name },
    { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-core-db.db_instance_address },
    { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-core-db.db_instance_port },
    { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-core-db.db_instance_username },
  ]
  uaa_secret = [
    {
      name      = "KEYCLOAK_ADMIN"
      valueFrom = "${data.aws_secretsmanager_secret.kc.arn}:KEYCLOAK_ADMIN::"
    },
    {
      name      = "KEYCLOAK_ADMIN_PASSWORD"
      valueFrom = "${data.aws_secretsmanager_secret.kc.arn}:KEYCLOAK_ADMIN_PASSWORD::"
    },
    {
      name : "SPRING_DATASOURCE_PASSWORD",
      valueFrom = "${module.store-core-db.db_instance_master_user_secret_arn}:password::"
    }

  ]
  control-plane_env = [
    { "name" : "SPRING_PROFILES_ACTIVE", "value" : "fargate" },
    { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.namespace}:4318" },
    { "name" : "OTEL_SDK_DISABLED", "value" : !var.is_monitoring },
    { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-POD-GATEWAY_PORT", "value" : "443" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_UAA_SCHEMA", "value" : "https" },
    { "name" : "COM_ASREVO_CVHOME_SERVICES_UAA_PORT", "value" : "443" },
    { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.namespace },
    {
      "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
      "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
    },

    { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE_NAMESPACE", "value" : "store-pod-1.${var.project}.lcl" },
    { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-core-db.db_instance_name },
    { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-core-db.db_instance_address },
    { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-core-db.db_instance_port },
    { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-core-db.db_instance_username },
  ]
  control-plane_secret = [
    {
      name      = "COM_ASREVO_CVHOME_STRIPE_KEY"
      valueFrom = "${data.aws_secretsmanager_secret.stripe.arn}:STRIPE_KEY::"
    },
    {
      name      = "COM_ASREVO_CVHOME_STRIPE_WEBHOOK"
      valueFrom = "${data.aws_secretsmanager_secret.stripe.arn}:STRIPE_WEBHOOK-SIGNING-KEY::"
    },
    {
      name : "SPRING_DATASOURCE_PASSWORD",
      valueFrom = "${module.store-core-db.db_instance_master_user_secret_arn}:password::"
    }
  ]

  services = {
    "seller-ui" = {
      public                      = true
      priority                    = 100
      service_type                = "SERVICE"
      loadbalancer_target_groups  = {}
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "seller-ui"
      main_container_port         = 8010
      health_check = {
        path                = "/"
        port                = 8010
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "seller-ui" = {
          image = "${var.docker_registry}/store-core/seller-ui:${var.image_tag}"
          environment : []
          secrets : []
          portMappings : [
            {
              name : "app",
              containerPort : 8010,
              hostPort : 8010,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "store-core-gateway" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {
        "gateway-tg" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["gateway-tg"].arn
          main_container                 = "store-core-gateway"
          main_container_port            = 8000
        }
      }
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "store-core-gateway"
      main_container_port         = 8000
      health_check = {
        path                = "/actuator/health"
        port                = 8000
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-core-gateway" = {
          image = "${var.docker_registry}/store-core/store-core-gateway:${var.image_tag}"
          environment : concat(local.store_core_gateway_env, local.pods_env)
          secrets : []
          portMappings : [
            {
              name : "app",
              containerPort : 8000,
              hostPort : 8000,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "uaa" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {
        "uaa-tg" : {
          loadbalancer_target_groups_arn = module.cluster-lb.target_groups["uaa-tg"].arn
          main_container                 = "uaa"
          main_container_port            = 8001
        }
      }

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "uaa"
      main_container_port         = 8001
      health_check = {
        path                = "/health"
        port                = 9000
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "uaa" = {
          image = "${var.docker_registry}/store-core/uaa:${var.image_tag}"
          environment : local.uaa_env
          secrets : local.uaa_secret
          portMappings : [
            {
              name : "app",
              containerPort : 8001,
              hostPort : 8001,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "control-plane" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "control-plane"
      main_container_port         = 8020
      health_check = {
        path                = "/actuator/health"
        port                = 8020
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "control-plane" = {
          image = "${var.docker_registry}/store-core/control-plane:${var.image_tag}"
          environment : concat(local.control-plane_env, local.pods_env)
          secrets : local.control-plane_secret
          portMappings : [
            {
              name : "app",
              containerPort : 8020,
              hostPort : 8020,
              protocol : "tcp"
            }
          ]
        }
      }
    }

  }
}


module "store-core-cluster" {
  source                             = "terraform-aws-modules/ecs/aws"
  cluster_name                       = "${local.module_name}-${var.project}-${var.env}"
  tags                               = var.tags
}

module "store-core-service" {
  source       = "git::https://github.com/cvhome-saas/cvhome-common-ecs-service.git?ref=main"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = each.key
  tags         = var.tags
  cluster_name = module.store-core-cluster.cluster_name
  env          = var.env
  module_name  = local.module_name
  project      = var.project
  service      = each.value
  subnet       = var.public_subnets
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow ingress traffic access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow egress traffic access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  auto_scale = var.pod_auto_scale
  for_each   = local.services
  vpc_id     = var.vpc_id
}

module "monitoring-collector-service" {
  source       = "git::https://github.com/cvhome-saas/cvhome-common-ecs-service.git?ref=main"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = "otel-collector"
  tags         = var.tags
  cluster_name = module.store-core-cluster.cluster_name
  env          = var.env
  module_name  = local.module_name
  project      = var.project
  service = {
    public              = true
    priority            = 100
    service_type        = "SERVICE"
    loadbalancer_target_groups = {}
    load_balancer_host_matchers = []
    desired             = 1
    cpu                 = 512
    memory              = 1024
    main_container      = "otel-collector"
    main_container_port = 4318
    health_check = {
      path                = "/"
      port                = 4318
      healthy_threshold   = 2
      interval            = 60
      unhealthy_threshold = 3
    }

    containers = {
      "otel-collector" = {
        image = "ashraf1abdelrasool/aws-otel-collector:latest"
        environment : [
          { "name" : "AWS_REGION", "value" : var.region }
        ]
        secrets : []
        portMappings : [
          {
            name : "app4317",
            containerPort : 4317,
            hostPort : 4317,
            protocol : "tcp"
          },
          {
            name : "app4318",
            containerPort : 4318,
            hostPort : 4318,
            protocol : "tcp"
          }
        ]
      }
    }
  }
  subnet = var.public_subnets
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow ingress traffic access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow egress traffic access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  auto_scale = var.pod_auto_scale
  vpc_id     = var.vpc_id
  count      = var.is_monitoring ? 1 : 0
}
