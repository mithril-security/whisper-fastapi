# Deploy to Azure

## Requirements

You need Azure CLI and terraform. For debian, install using

```sh
# Install azure-cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Install confcom extension for azure-cli
az extension add -n confcom
# Install terraform
sudo snap install terraform
```

Log into Azure.

```sh
# Log in using azure-cli
az login
```

The login command will output something like this to the terminal.
```json
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Visual Studio Enterprise",
    "state": "Enabled",
    "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "user": {
      "name": "xxxxxxxxxxxxx@xxxxx",
      "type": "user"
    }
  },
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "isDefault": false,
    "managedByTenants": [
      {
        "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      }
    ],
    "name": "Microsoft Azure Sponsorship",
    "state": "Enabled",
    "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "user": {
      "name": "xxxxxxxxxxxxx@xxxxx",
      "type": "user"
    }
  }
]
```

From this list, find the subscription name you want to use - and set it as default using:

```sh
# Set the subscription azure-cli will use by default.
az account set --subscription "Microsoft Azure Sponsorship"
```

## Deploy

```sh
# Init the terraform state & install providers
terraform init
# Show the changes to apply
terraform plan
# Apply the changes
terraform apply
```

If you've changed the docker image, you should run this command to force terraform to rebuild it.
```sh
# Mark docker_image.image as outdated
terraform taint docker_image.image
```

To delete the deployment, run
```sh
# Destroy everything that was created
terraform destroy
```
