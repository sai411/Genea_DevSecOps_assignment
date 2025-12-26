# Genea_DevSecOps_assignment

# Project overview

This project demonstrates a production-grade DevSecOps workflow for deploying a containerized User Management service on AWS using Terraform, GitHub Actions, and Amazon ECS.

This application provides a simple user management service that stores and manages user details in a MySQL database.
It is designed to demonstrate secure, production-ready deployment practices using containerization and automated DevSecOps workflows.

The solution emphasizes:

-> Infrastructure as Code (IaC)

-> Secure CI/CD pipelines

-> Manual, controlled database migrations

-> OIDC-based authentication

-> Idempotent and rollback-friendly deployments

# Architecture Overview - High-Level Flow

Developer Pushes the code 
   ↓
GitHub Repository
   ↓
CI Pipeline (Build + Scan + Push)
   ↓
ECR (Docker Images)
   ↓
Manual DB Migration (ECS RunTask)
   ↓
Manual CD (ECS Service Deployment)

--> Infrastructure provisioning follows the same flow:

Code pushed to the Terraform directory of the GitHub repository will trigger the Terraform IaC pipeline and create or update the infrastructure.

# To Test application locally

```
git clone https://github.com/sai411/Genea_DevSecOps_assignment.git

cd app

docker build -t testing_app .

docker run -dit -p 8000:8000 testing_app (this will work only for /health endpoint, require database to make it fully work)
```

# terrafom pipeline

I have used terraform for IAC and created these resources using the tf scripts. 

VPC, subnets, routetables , ECS cluster and services , RDS database in private subnet , IAM roles and policies, GitHub OIDC identity provider, CloudWatch logging with KMS encryption

To run the Terraform pipeline, a user needs to push code changes to any Terraform directory file or create a pull request to the main branch.

To deploy these resources, an IAM role or user is required. Instead of using long-lived credentials, GitHub Actions OIDC authentication is used with an IAM role to assume short-lived credentials securely.

To accommodate this use case, an IAM identity association with GitHub OIDC was created along with an IAM role GITHUB_ACTIONS_IAC_ROLE with the required permissions to provision AWS resources used in this project. Terraform uses this role to assume permissions and provision infrastructure.

Terraform remote backend is configured using an S3 bucket to store the state file.

```
git clone https://github.com/sai411/Genea_DevSecOps_assignment.git

cd terraform

terraform init 

terraform plan

terraform apply --auto-approve

```

Note:

The OIDC IAM role must be created prior to Terraform execution, as Terraform uses it to provision resources.

AWS Secrets Manager is used for storing RDS (MySQL) credentials. The secret must be created before provisioning and referenced using Terraform data resources.

To test locally, update the secret ARN in variables.tf of the RDS module.

Benefits: No AWS secrets stored in GitHub , Short-lived credentials, Least-privilege IAM roles

# CI pipeline

This pipeline will be triggered when any one pushed the changes or created a PR to the app/test directory where the actual application and test cases will be available.

This pipeline included checkout , Run unit tests, Static code analysis, Dependency vulnerability scanning, Dependency vulnerability scanning, Build Docker image, Scan container image (Trivy) and finally Push image to Amazon ECR.


# DB migration

Database migrations involve schema changes, column additions, or deletions. These changes are not performed continuously and are executed only when required.

SQL migration scripts are stored in a directory and executed using a Python-based migration runner. The migration runner is packaged as a Docker image and executed as a one-time ECS RunTask, not as a long-running service.

This migration process is manually triggered to ensure controlled and safe schema changes.

If new SQL scripts are required, they can be added to the migration directory, and the migration pipeline can be triggered manually. The execution logic ensures idempotency so migrations can be safely re-run.

# CD pipeline

This is the final deployment stage of the usermanagement applciation , Where this was also a pipeline which needs a manual intervenction, I choose like this because , the DB migration will be done prior to this and best practice will be manual trigger of fianl CD pipleine , which helps to handle the various environment deployments.

This pipeline consists of steps which will pull the ECR image and deploy into ECS service , which consists of ALB. The same ECS Service was enabled with conatiner insights with OTEL collector and configred to push the logs to cloudwatch.

As I don't have the doamin name with me to configure the SSL traffic, I have deployed the applciation with HTTP at ALB level. The Database will be fully secured which will allows the traffic from ECS service/task.

Onec the domain name is avaialbe , We can update the Terraform code to add the listener to configure SSL and its certifiacate. So now onec the deployment is completed, you can access the serviec by the below process.

```
Open your browser 
<alb_dns>/users to see the user details
<alb_dns>/health to see the applivation was healthy or not 

Run the curl command or an api call from postman to add the data to the database.

curl -X POST \
  <alb_dns>/user_add \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sai",
    "email": "sai@example.com"
  }'

  Then you can observe the data by visiting <alb_dns>/users

```
