# Introduction 
## LogicApp IAC Bicep Deployment with vnet and CosmosDb ##
IOT devices send monitoring data to an IOT Hub in Azure that route the data to a servicebus.<br/>
An Logic App reads from the servicebus and stores in the database.<br/>

# Getting Started
Deploy via Azure Pipeline defined in pipeline\deployLogicAppExample.yaml, or with:<br/>
    1. testRun\deployLogicAppIntegrationVnetAndSubnets.ps1<br/>
    2. testRun\deployLogicAppIntegration.ps1<br/>

# Build and Test
After deployment, perform these manual steps:<br/>
    1. Register a device at the IOT Hub.<br/>
    2. Install the IOT Hub extension in Visual Studio Code.<br/>
    3. Connect to the device at the IOT Hub with the IOT Hub extension in Visual Studio Code.<br/>
    4. Send test messages. Check that they arrive at the cosmosd db account created from the IAC deployment using the Azure Gui.<br/>

# Contribute
The following needs to be done:<br/>
    1. API Connections defined in workflows\connections.json must be created with IAC Bicep<br/>
    2. Workflows\connections.json must be altered and configured dynamically with environment it is deployed to and the API Connections defined in step #1.<br/>
    3. Workflows in Logic App must be deployed automatically with pipeline, setup is already there. Needs to be tested and verified.<br/>
    4. Complete network isolation. As of now, infrastructure parts are allowing public access until network isolation setup is complete. This means changing all enablePublicNetworkAccess parameters to false for everything except is the IOT Hub and complete working message functionality after this is set up.<br/>
    5. CosmosDb is used as a database. The final database solution must be compatible with Grafana<br/>
    6. Pipeline in pipeline\deployLogicAppExample.yaml must be completed and tested / verified.<br/>


[See more details here](logicAppCosmosDb.md)
