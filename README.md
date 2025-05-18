# Ethereum EKS Terragrunt Deployment (Non-Production)

This guide outlines the steps to deploy and manage the Ethereum EKS cluster in a non-production environment using Terragrunt.

## Deployment Steps

1.  **Navigate to the Non-Production Directory:**

    Change your current directory to the root of the non-production environment configuration.
    ```bash
    cd ethereum-eks-terragrunt/live/non-prod
    ```

2.  **Preview Changes:**

    Before applying any changes, it's recommended to view the execution plan. This command will show you what resources Terragrunt will create, modify, or destroy across all modules in this environment.
    ```bash
    terragrunt run-all plan
    ```

3.  **Apply Configuration:**

    To deploy or update all modules in the non-production environment, run the following command. The `-auto-approve` flag will apply the changes without interactive confirmation.
    ```bash
    # Run the apply command for all modules in this folder.
    terragrunt run-all apply -auto-approve
    ```

## Managing the EKS Cluster (Cost Optimization)

To manage costs, you can destroy the EKS cluster when it's not in use and recreate it when needed.

### Destroying the EKS Cluster

1.  **Navigate to the EKS Cluster Directory:**

    ```bash
    cd ethereum-eks-terragrunt/live/non-prod/ap-southeast-1/dev/eks/ethereum/
    ```

2.  **Destroy the Cluster:**

    This command will destroy only the EKS cluster resources. The `-auto-approve` flag will proceed without confirmation.
    ```bash
    terragrunt destroy -auto-approve
    ```

### Creating Only the EKS Cluster

If you have previously destroyed the EKS cluster or want to create only this specific module:

1.  **Navigate to the EKS Cluster Directory:**

    ```bash
    cd ethereum-eks-terragrunt/live/non-prod/ap-southeast-1/dev/eks/ethereum/
    ```

2.  **Apply the EKS Cluster Configuration:**

    This command will create or update the EKS cluster resources. The `-auto-approve` flag will apply the changes without interactive confirmation.
    ```bash
    terragrunt apply -auto-approve
    ```