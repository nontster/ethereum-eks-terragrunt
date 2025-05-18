Change directory to root of non-production environment
```bash
cd ethereum-eks-terragrunt/live/non-prod
```

View plan output
```bash
terragrunt run-all plan
```

Apply the plan
```bash
# Run the apply command for all modules in this folder.
terragrunt run-all apply -auto-approve
```

