az deployment group create --resource-group 'poc' --template-file ../deployLogicAppIntegrationVnetAndSubnets.bicep --parameters location='West Europe' resourceNamePrefix='dev'
