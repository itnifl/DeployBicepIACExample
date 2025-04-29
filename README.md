# Introduction 
## LogicApp IAC Bicep Deployment with vnet and CosmosDb ##
IOT devices send monitoring data to an IOT Hub in Azure that route the data to a servicebus.
An Logic App reads from the servicebus and stores in the database.

# Getting Started
Deploy via Azure Pipeline defined in pipeline\deployLogicAppExample.yaml, or with:
    1. testRun\deployLogicAppIntegrationVnetAndSubnets.ps1
    2. testRun\deployLogicAppIntegration.ps1

# Build and Test
After deployment, perform these manual steps:
    1. Register a device at the IOT Hub.
    2. Install the IOT Hub extension in Visual Studio Code.
    3. Connect to the device at the IOT Hub with the IOT Hub extension in Visual Studio Code.
    4. Send test messages. Check that they arrive at the cosmosd db account created from the IAC deployment using the Azure Gui.

# Contribute
The following needs to be done:
    1. API Connections defined in workflows\connections.json must be created with IAC Bicep
    2. Workflows\connections.json must be altered and configured dynamically with environment it is deployed to and the API Connections defined in step #1.
    3. Workflows in Logic App must be deployed automatically with pipeline, setup is already there. Needs to be tested and verified.
    4. Complete network isolation. As of now, infrastructure parts are allowing public access until network isolation setup is complete. This means changing all enablePublicNetworkAccess parameters to false for everything except is the IOT Hub and complete working message functionality after this is set up.
    5. CosmosDb is used as a database. The final database solution must be compatible with Grafana
    6. Pipeline in pipeline\deployLogicAppExample.yaml must be completed and tested / verified.


[See more details here](logicAppCosmosDb.md)