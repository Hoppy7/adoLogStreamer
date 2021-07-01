# adoLogStreamer

[![Build Status](https://dev.azure.com/hoppy7/Azure/_apis/build/status/Hoppy7.adoLogStreamer?branchName=main)](https://dev.azure.com/hoppy7/Azure/_build/latest?definitionId=12&branchName=main)

## Overview
Azure DevOps currently offers no out-of-the-box functionality to stream pipeline logs to blob storage/Log Analytics/Event Hub/etc, and this sample can be used to fill in the gaps. 

<br>

## Log Stream Flow
![image](https://user-images.githubusercontent.com/18079003/116765233-09106980-a9d9-11eb-8f7c-12cb1ee94c0f.png)

  1.  [Templates/streamLogs.yml](https://github.com/Hoppy7/adoLogStreamer/blob/main/templates/streamLogs.yml) template stage gets the pipeline definition run's current context and puts it on the storage queue
  
  2.  Function app triggers and processes message
  
  3.  Function app calls the Azure DevOps [Pipeline List Logs API](https://docs.microsoft.com/en-us/rest/api/azure/devops/pipelines/logs/list?view=azure-devops-rest-6.0) and downloads the pipeline run's logs
  
  4.  Function app pushes the pipeline run's logs to blob storage

<br>

## Implementation
  1.  [Create](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#create-a-pat) or get your Azure DevOps Personal Access Token (PAT)

  2.  Create a secret in Azure Key Vault named "adoLogStreamerPat" that will securely store the Azure DevOps PAT token.  This is set as a [keyvault reference](https://docs.microsoft.com/en-us/azure/app-service/app-service-key-vault-references) in the function app's app settings in the [arm template](https://github.com/Hoppy7/adoLogStreamer/blob/main/armTemplates/deploy.json).
  
    $pat = "<pat_token>"
    $vaultName = "<keyvault_name>"
    Set-AzKeyVaultSecret -VaultName $vaultName -Name "adoLogStreamerPat" -SecretValue $(ConvertTo-SecureString -AsPlainText $pat -Force)
      
  3.  Update the [pipeline's variables](https://github.com/Hoppy7/adoLogStreamer/blob/main/azure-pipelines.yml#L12-L30) listed in the below table with your own values

      Variable Name | Value Description
      ------ | ------
      azureSubscription | The name of the service connection the pipeline will leverage to deploy the arm template
      resourceGroupName | The name of the resource group the function app and storage account will be deployed
      location | The region the Azure resource group and resources will be deployed
      functionAppName | The name of the Azure function app.  **Note this must be a globally unique resource name**
      azureDevOpsOrg | The name of the Azure DevOps Organization
      azureDevOpsProject | The name of the Azure DevOps Project
      adoPatKeyvaultSecretUri | The uri of the secret created from #2 - https://{vaultName}.vault.azure.net/secrets/adoLogStreamerPat/
      storageAccountName | The name of the storage account used by the function app to store logs.  **Note this must be a globally unique resource name**

  4.  Run the pipeline to deploy the arm template and the function app package

  5.  Grant the function app's MSI access to the keyvault so it can access the adoPatKeyvaultSecretUri keyvault reference app setting
  
    $functionAppName = "<functionApp_name>"
    $vaultName = "<keyvault_name>"
    $vaultRG = "<keyvault_resourceGroup>"
    $msi = Get-AzADServicePrincipal -SearchString $functionAppName
    Set-AzKeyVaultAccessPolicy -VaultName $vaultName -ResourceGroupName $vaultRG -ServicePrincipalName $msi.ApplicationId.Guid -PermissionsToSecrets "get, list"
    
    
  ![image](https://user-images.githubusercontent.com/18079003/117528888-494b8b00-af89-11eb-9bda-2d6822c7c13d.png)
