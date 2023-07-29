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






# Release Notes

New features, bug fixes and changes [can be found here](https://github.com/Azure-Player/azure.synapse.tools/blob/master/changelog.md).

# Misc

## New feature requests
Tell me your thoughts or describe your specific case or problem.  
For any requests on new features please raise a new issue here: [New issue](https://github.com/Azure-Player/azure.synapse.tools/issues)  
