
## Sample Commands for Local Validation 

Terraform Version - 0.13.4
https://registry.terraform.io/modules/Azure/aks/azurerm/latest

The remote backend is stored locally.

```bash
    #Init Example 
    cd azure/azure-object-storage
    terraform init -backend-config='inputs/dev/backend.tfvars' 
```

```bash
    #Plan Example 
    cd azure/azure-object-storage
    terraform plan -var-file='inputs/dev/backend.tfvars' -var-file='inputs/dev/azure-infra.tfvars'
```

```bash
    #Apply  Example 
    cd azure/azure-object-storage
    terraform apply -var-file='inputs/dev/backend.tfvars' -var-file='inputs/dev/azure-infra.tfvars'
```

