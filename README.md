# azure.synapse.tools
<img style="float: right;" src="./images/Azure-Synapse-tools-256-logo.png" width="256px">

## What is supported
The deployment of these objects:  
- Workspace instance
- dataset
- dataflow
- integration runtime
- linked service
- pipeline
- KQL script *
- SQL script *
- notebook *
- Spark job definition *

> \* via RestAPI only

## What is NOT yet supported
The deployment of these objects:
- credential
- 'AzResource' deployment method 
- Apache Spark pools (BigDataPool - #11)


# How to start

## Install-Module

To install the module, open PowerShell command line window and run the following lines:

```powershell
Install-Module -Name azure.synapse.tools -Scope CurrentUser
Import-Module -Name azure.synapse.tools
```

If you want to upgrade module from a previous version:

```powershell
Update-Module -Name azure.synapse.tools
```

Check your currently available version of module:
```powershell
Get-Module -Name azure.synapse.tools
```

The module is available on [PowerShell Gallery](https://www.powershellgallery.com/packages/azure.synapse.tools).

## Publish Options
* DeleteNotInSource: Deletes objects in destination that does not exist in source.
* IncrementalDeployment: Deployment state file to only deploy changed objects in the source.

### Incremental Deployment

The Synapse service does not have global parameter capability as in Azure Data Factory (ADF). In order to maintain a deployment state of changed objects, a storage account and json file will hold the deployment state. The file will be in the naming convention: `<synapse-workspace-name>_deployment_state.json`. If `IncrementalDeployment` is used, please find the prerequisites below.

1. Authenticated user with `Storage Blob Data Contributor` rbac role on the destination storage account.
2. `azure-synapse-tools` container is required prior to deploying a Synapse workspace.

# Release Notes

New features, bug fixes and changes [can be found here](https://github.com/Azure-Player/azure.synapse.tools/blob/master/changelog.md).

# Misc

## New feature requests
Tell me your thoughts or describe your specific case or problem.  
For any requests on new features please raise a new issue here: [New issue](https://github.com/Azure-Player/azure.synapse.tools/issues)  
