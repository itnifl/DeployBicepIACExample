az deployment group create --resource-group 'poc' --template-file ../deployLogicAppIntegration.bicep --parameters location='westeurope' resourceNamePrefix='dev'
