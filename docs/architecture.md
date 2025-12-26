# Architecture Overview

The following diagram represents the high-level architecture of the Genea User Management DevSecOps solution and how different components interact across the CI/CD lifecycle.

![Architecture Diagram] Link mentioned in the file simple_architecture_link

The diagram represents a single-region, highly available setup using multi-AZ subnets

The architecture diagram illustrates how the Genea User Management application is deployed securely inside AWS using a layered network design. All resources are hosted within a single AWS region and isolated inside a dedicated VPC.

Public subnets are used only for internet-facing components such as the Application Load Balancer and the NAT Gateway. Incoming traffic reaches the Application Load Balancer, which routes requests to the ECS service running in private subnets. The ECS tasks are never exposed directly to the internet, ensuring application-level isolation.

The ECS service runs across multiple private subnets to provide high availability. Container Insights and CloudWatch Logs are enabled for observability, allowing metrics and logs to be collected securely. Outbound internet access for the ECS tasks is provided through the NAT Gateway, which is required for operations such as pulling container images and accessing external services.

The MySQL RDS database is deployed in private subnets using a subnet group spanning multiple availability zones. It is accessible only from the ECS service and migration tasks, preventing any direct public access. Database credentials are stored securely using AWS Secrets Manager.

VPC Flow Logs are enabled to capture network traffic metadata for auditing and security monitoring. All logs are encrypted using AWS KMS to ensure compliance and data protection. The architecture was created with all security measures taken into consideration whereever possible.
