This project follows a controlled and production-oriented deployment approach using Terraform, GitHub Actions, and Amazon ECS. The overall deployment is intentionally divided into infrastructure provisioning, continuous integration, database migration, and final application deployment so that each stage can be validated independently and rolled back safely if required.

Infrastructure deployment is handled entirely using Terraform. All AWS resources required for this application are provisioned as code, including the VPC, public and private subnets, route tables, internet gateway, NAT gateway, ECS cluster and service, Application Load Balancer, RDS MySQL database in a private subnet, IAM roles and policies, GitHub OIDC identity provider, CloudWatch log groups with KMS encryption, and Secrets Manager for database credentials. Terraform runs through a GitHub Actions pipeline that is triggered whenever changes are pushed or a pull request is raised against the Terraform directory. The pipeline uses GitHub OIDC to assume an IAM role, which avoids storing long-lived AWS credentials in GitHub and ensures short-lived, least-privilege access during infrastructure provisioning.

This pipeline steps contains: Checkout, Configure AWS credentials (OIDC), Setting up Terraform, initilization, Terraform Format, validate and TFLint, tfsec finally plan and apply. Terraform code has been fully scanned and with best practices , minimal policies used where ever needed, evrything with encyption, and with restricted security groups and networking to enable security.

To Create the Terraform resources some manual changes is required in the aws and github actions before triggering the pipeline.

1. Create an OIDC association in IAM webidentity providers

--> Click on create identity provider
--> Add the URL as https://token.actions.githubusercontent.com
--> Set audiance as sts.amazonaws.com
--> Create the association

2. Create an IAM role used for Terraform to create the resources

--> Create a role, add the reustpolicy ad below

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::211395678080:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:sai411/Genea_DevSecOps_assignment:*"
                }
            }
        }
    ]
}

--> Attach policies with least privilege acess, As we are using this for Infrastructure provisioning, So We need poweruser access, to seamlessly use this role to deploy resources, as it was restricted to used by a partuclular repo.

--> Attach poweruser policy and create the role 

3. Add secret in Github actions

--> Create a Secret in github actions 
--> add Key as "AWS_IAC_ROLE_ARN" and value add the role arn that was created above.
--> save that , I have already used the same in the Terraform code.

4. Create two ECR repos which was as one time activity,  so I don't want to make any changes to them when terrfaorm reconciles again by any trigger. Hence two repo were needed one for application and other for DB migration activiy images.
Add these as well in the secrets as ECR_REPOSITORY_DB, ECR_REPOSITORY and ECS_CLUSTER_NAME as a variable

5. Secrets manager creation is also needed in prior becuase I want the ECS task definition securely import the credentials from secrest manager not to visibile even in the team or organization. Hence create a secret manager and add the key as username and value as "<your-username>", another key as password , value as "<your-password>"

6. As we are using sonarqube for scaning, the server details and token shoul require to sue in the process of authentication and authorization, Hence add these SONAR_PROJECT_KEY, SONAR_TOKEN as a secrets and SONAR_HOST_URL as a variable


Once the infrastructure is in place, the continuous integration pipeline is triggered when changes are made to the application or test directories. This pipeline checks out the source code, installs dependencies, runs unit tests, performs static code analysis, scans dependencies for vulnerabilities, builds the Docker image, scans the container image using Trivy, and finally pushes the verified image to Amazon ECR. Only images that pass all security and quality checks are published, ensuring that insecure artifacts never reach the deployment stage.

Database migrations are handled separately from application deployment and are executed manually. This design choice was intentional, as schema changes are sensitive and should not run automatically with every deployment. SQL migration files are stored in a dedicated migrations directory and are written to be idempotent, meaning they can be executed multiple times without causing failures or duplicate changes. A lightweight Python script runs all available SQL files inside a container, and this container is executed as a one-time ECS RunTask within the same cluster and network as the application. The migration workflow is manually triggered in GitHub Actions whenever a schema change is required, providing full control and auditability over database modifications.

The final application deployment is also manually triggered through a GitHub Actions workflow. During deployment, the user selects the Docker image tag to be deployed from ECR. The pipeline retrieves the existing ECS task definition, updates only the container image version, registers a new task definition revision, and updates the ECS service with a forced new deployment. The workflow then waits until the service reaches a stable state before completing. This approach makes rollbacks straightforward, as redeploying a previous image version simply requires rerunning the deployment workflow with an older tag.

After deployment, the application is accessible through the Application Load Balancer DNS name. Health checks and user management endpoints are exposed over HTTP, as a domain and SSL certificate were not configured for this assignment. The database remains fully isolated within a private subnet and only allows access from ECS tasks and services. Logs from both the application and migration tasks are available in CloudWatch for troubleshooting and auditing.