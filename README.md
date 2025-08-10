# Base AWS Infrastructure

A comprehensive Terraform-based infrastructure setup for hosting cloud-native applications on AWS. This repository provides reusable, modular infrastructure components that can be deployed across multiple environments (development, staging, production).

## 🚀 What This Creates

This Terraform configuration will provision:

### Core Infrastructure Components
- **VPC with Multi-AZ Setup**: Secure network foundation with public and private subnets
- **Amazon EKS Cluster**: Managed Kubernetes service with worker nodes
- **Application Load Balancer**: HTTP traffic distribution
- **ECR Repository**: Container image storage
- **OIDC Provider**: Secure GitHub Actions authentication (no static credentials)

### Security & Networking
- Internet Gateway for public subnet access
- NAT Gateways for private subnet outbound connectivity
- Security Groups with least-privilege access
- IAM roles and policies following AWS best practices
- Route tables for proper traffic flow

## 📋 Prerequisites

Before you begin, ensure you have:

### Required Tools
- **Terraform** >= 1.12.0 ([Download here](https://www.terraform.io/downloads.html))
- **AWS CLI** >= 2.0 ([Installation guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html))

### AWS Account Setup
- AWS Account with administrative access
- AWS CLI configured with appropriate credentials:
  ```bash
  aws configure
  ```
- Required AWS permissions for creating:
  - VPC and networking resources
  - EKS clusters and node groups
  - IAM roles and policies
  - Load balancers and target groups
  - ECR repositories

## 🛠️ Quick Start

### Step 1: Create S3 Bucket for Remote State (One-time Setup)

**Important**: Terraform requires an S3 bucket to store its state remotely. Create this first:

```bash
# Create S3 bucket for Terraform state (replace with your unique name)
aws s3 mb s3://your-terraform-state-bucket-12345 --region us-east-1

# Enable versioning (handles state file recovery)
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket-12345 \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket-12345 \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket your-terraform-state-bucket-12345 \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

**⚠️ Important**: Replace `your-terraform-state-bucket-12345` with a globally unique bucket name. This bucket will store Terraform state for both your infrastructure and application deployments.


### Step 2: Clone and Prepare

```bash
# Clone the repository
git clone https://github.com/Rippyblogger/Base-AWS-Infrastructure.git
cd Base-AWS-Infrastructure

Modify the `bucket' parameter of the existing backend configuration in the `provider.tf` file:

```hcl
terraform {
  backend "s3" {
    bucket  = "your-terraform-state-bucket-12345"  # Use your actual bucket name
    key     = "infrastructure/terraform.tfstate"
    region  = "us-east-1"                          # Match your bucket region
    encrypt = true
  }
}
```

# Initialize Terraform
```
terraform init
```

### Step 3: Configure Your Infrastructure

The main Terraform configuration uses modular architecture. Here's a sample of how the modules are called with real values:

```hcl
# main.tf - Example module configuration

module "networking" {
  source         = "./modules/networking"
  region         = "us-east-1"                    # AWS region for deployment
  vpc_cidr_block = "10.0.0.0/16"                # VPC CIDR block
  public_subnets = {
    Main_public_1 = "10.0.0.0/18"               # Public subnet 1
    Main_public_2 = "10.0.64.0/18"              # Public subnet 2
  }
  private_subnets = {
    Main_private_1 = "10.0.128.0/18"            # Private subnet 1
    Main_private_2 = "10.0.192.0/18"            # Private subnet 2
  }
  cluster_name = "My_EKS_Cluster"               # EKS cluster name
}

module "eks" {
  source               = "./modules/eks"
  cluster_name         = "My_EKS_Cluster"       # Must match networking module
  cluster_version      = "1.32"                 # Kubernetes version
  node_group_name      = "EKS_Node_group"       # Node group identifier
  private_subnets      = module.networking.private_subnets
  vpc_cidr_block       = module.networking.vpc_cidr_block
  capacity_type        = "ON_DEMAND"            # ON_DEMAND or SPOT
  instance_types       = ["t3.medium"]          # Node instance types
  vpc_id               = module.networking.vpc_id
  alb_security_group_id = module.load_balancer.lb_security_id
  instance_type        = "t3.medium"            # Primary instance type
  ecr_repo_name        = "golang_api"           # ECR repository name
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  private_subnets     = module.networking.private_subnets
  vpc_id              = module.networking.vpc_id
  vpc_cidr_block      = module.networking.vpc_cidr_block
  lb_logs_bucket_name = "lb-accesslogs25-bucket649823"  # S3 bucket for ALB logs (must be globally unique)
}

module "oidc" {
  source            = "./modules/oidc"
  github_branch     = "main"                    # GitHub branch for deployments
  github_username   = "Rippyblogger"            # Your GitHub username
  github_repository = "golang_api"              # Your application repository
  eks_cluster_name  = module.eks.cluster_name
}
```

### Required Variables You Must Customize

**Before deploying, update these values in your `main.tf`:**

| Variable | Current Value | What to Change |
|----------|---------------|----------------|
| `region` | `"us-east-1"` | Your preferred AWS region |
| `cluster_name` | `"My_EKS_Cluster"` | Your cluster name (alphanumeric + underscores) |
| `github_username` | `"Rippyblogger"` | **Your GitHub username** |
| `github_repository` | `"golang_api"` | **Your forked repository name** |
| `lb_logs_bucket_name` | `"lb-accesslogs25-bucket649823"` | **Globally unique S3 bucket name** |
| `ecr_repo_name` | `"golang_api"` | Your ECR repository name |

### Optional Customizations

```hcl
# You can also modify these based on your needs:
vpc_cidr_block    = "10.0.0.0/16"        # Change if conflicts with existing networks
cluster_version   = "1.32"               # Use latest stable Kubernetes version
instance_type     = "t3.medium"          # t3.small for dev, t3.large for prod
capacity_type     = "ON_DEMAND"          # Use "SPOT" for cost savings (less reliable)
```

### Step 4: Review and Deploy

```bash
# Review what will be created
terraform plan

# Deploy the infrastructure
terraform apply
```

## 📁 Project Structure

```
Base-AWS-Infrastructure/
├── main.tf                    # Main Terraform configuration
├── variables.tf              # Input variables
├── outputs.tf               # Output values
├── versions.tf              # Provider version constraints
├── terraform.tfvars.example # Example variable values
├── modules/
│   ├── vpc/
│   │   ├── main.tf          # VPC, subnets, gateways, route tables
│   │   ├── variables.tf     # VPC module variables
│   │   └── outputs.tf       # VPC module outputs
│   ├── eks/
│   │   ├── main.tf          # EKS cluster and node groups
│   │   ├── variables.tf     # EKS module variables
│   │   └── outputs.tf       # EKS module outputs
│   ├── load_balancer/
│   │   ├── main.tf          # Application Load Balancer
│   │   ├── variables.tf     # ALB module variables
│   │   └── outputs.tf       # ALB module outputs
│   └── oidc/
│       ├── main.tf          # OIDC provider for GitHub Actions
│       ├── variables.tf     # OIDC module variables
│       └── outputs.tf       # OIDC module outputs
└── README.md                # This file
```

## 🔧 Module Details

### VPC Module (`modules/vpc/`)
Creates a robust networking foundation:
- **VPC**: Main network container with DNS support
- **Public Subnets**: 2 subnets across different AZs for load balancers
- **Private Subnets**: 2 subnets for EKS worker nodes and applications
- **Internet Gateway**: Enables public subnet internet access
- **NAT Gateways**: Provides outbound internet for private subnets
- **Route Tables**: Directs traffic appropriately

### EKS Module (`modules/eks/`)
Provisions a managed Kubernetes cluster:
- **EKS Cluster**: Control plane managed by AWS
- **Node Groups**: Auto-scaling worker nodes
- **IAM Roles**: Service and node group roles with required policies
- **Security Groups**: Network access controls
- **Add-ons**: Essential cluster add-ons (VPC CNI, CoreDNS, kube-proxy)

### Load Balancer Module (`modules/load_balancer/`)
Sets up application traffic distribution:
- **Application Load Balancer**: Layer 7 load balancing
- **Target Groups**: Health checking and traffic routing
- **Listeners**: HTTP/HTTPS traffic handling
- **Security Groups**: Load balancer access controls

### OIDC Module (`modules/oidc/`)
Enables secure GitHub Actions integration:
- **OIDC Identity Provider**: Secure authentication without static credentials
- **IAM Roles**: GitHub Actions execution roles
- **Trust Policies**: Granular repository access controls

## 🔧 Configuration Options

### Essential Variables

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `aws_region` | AWS region for resources | `string` | `"us-west-2"` |
| `cluster_name` | Name for the EKS cluster | `string` | `"my-app-cluster"` |
| `environment` | Environment name (dev/staging/prod) | `string` | `"production"` |
| `availability_zones` | AZs for multi-AZ deployment | `list(string)` | `["us-west-2a", "us-west-2b"]` |

### Network Configuration

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `vpc_cidr` | CIDR block for VPC | `string` | `"10.0.0.0/16"` |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | CIDR blocks for private subnets | `list(string)` | `["10.0.3.0/24", "10.0.4.0/24"]` |

### EKS Configuration

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `node_instance_type` | EC2 instance type for nodes | `string` | `"t3.medium"` |
| `node_desired_capacity` | Desired number of nodes | `number` | `2` |
| `node_max_capacity` | Maximum number of nodes | `number` | `4` |
| `node_min_capacity` | Minimum number of nodes | `number` | `1` |

### GitHub Integration (Optional)

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `github_org` | GitHub organization/username | `string` | `"your-username"` |
| `github_repo` | Repository name for OIDC access | `string` | `"your-app-repo"` |

```

## 🔄 Integration with Applications

This infrastructure is designed to work with containerized applications. After deployment:

1. **Configure kubectl**: Use the EKS cluster for application deployment
2. **Push container images**: Use the ECR repository for image storage
3. **Deploy applications**: Use Kubernetes manifests or Terraform
4. **Access applications**: Through the Application Load Balancer

## 🧹 Cleanup

To destroy all resources:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy
```

**⚠️ Warning**: This will permanently delete all resources. Make sure you have backups of any important data.

**Next Steps**: After deploying this infrastructure, you can deploy your applications using the [Golang API repository](https://github.com/Rippyblogger/golang_api) or any other containerized application.