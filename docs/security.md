Security is built into every stage of this project rather than being treated as an afterthought. Infrastructure provisioning, application delivery, and runtime operations all follow the principle of least privilege and avoid the use of long-lived credentials wherever possible.

AWS access from GitHub Actions is handled using OIDC-based authentication, which allows the pipelines to assume IAM roles dynamically without storing AWS access keys in the repository or in GitHub secrets. These roles are scoped with minimal permissions required for Terraform, CI, and deployment activities, reducing the blast radius in case of misuse Infrastructure Code is written in terraform and I have used all possible sucurity and validation scans.

Secrets such as database credentials are stored securely in AWS Secrets Manager and injected at runtime into ECS tasks. Sensitive values are never hardcoded into source code, Docker images, or task definitions. This ensures credentials remain protected and can be rotated independently of application deployments.

Network security is enforced by isolating the database in private subnets and allowing access only from ECS services and migration tasks through tightly scoped security groups. Public access is limited to the Application Load Balancer, which serves as the only external entry point to the application.

Multiple security scans are integrated into the CI pipeline, including static code analysis, dependency vulnerability scanning, and container image scanning. These checks help identify issues early in the development lifecycle and prevent vulnerable code or images from reaching production.

Database migrations and deployments are intentionally manual and controlled to avoid unintended changes. This approach reduces the risk of accidental data loss or unauthorized schema modifications, aligning the project with real-world production security practices.