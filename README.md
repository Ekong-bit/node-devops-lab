# node-devops-lab

A mini DevOps project to demonstrate CI/CD for a Node.js app:
- **Node/Express** app (with tests)
- **Docker** container
- **Terraform** infra (Jenkins on EC2, ECR, S3, Elastic Beanstalk, CloudWatch) in **eu-west-2**
- **Jenkins** pipeline builds/tests, pushes to **ECR**, deploys to **Elastic Beanstalk**

## Architecture (high level)
GitHub → Jenkins (EC2, IAM role)
      → build & test → Docker image → ECR
      → create Dockerrun + zip → S3
      → create EB app version → update EB env (ALB)
Users → (HTTPS later) → EB → container (port 3000)
CloudWatch: Logs + CPU alarms

## Quickstart
- `app/` Node app with Jest tests.
- `infra/` Terraform stack (initialize with \`terraform init\`).
- Jenkinsfile drives CI/CD.

## Commands
- Run tests: \`(cd app && npm ci && npm test)\`
- Build Docker locally: \`(cd app && docker build -t node-devops-lab:dev .)\`
- Terraform plan/apply: \`(cd infra && terraform init && terraform apply)\`
