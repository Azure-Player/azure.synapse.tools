<#
.SYNOPSIS
Stops all triggers in Azure Data Factory instance (service).

.DESCRIPTION
Stops (disables) all triggers in Azure Data Factory instance (service).

.PARAMETER FactoryName
Name of Azure Data Factory service to be affected.

.PARAMETER ResourceGroupName
Resource Group Name of Synapse Workspace service to be affected.

.EXAMPLE
$ResourceGroupName = 'rg-devops-factory'
$DataFactoryName = "SQLPlayerDemo"
Stop-SynapseTriggers -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"

.LINK
Online version: https://github.com/SQLPlayer/azure.datafactory.tools/
#>
function Stop-SynapseTriggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $FactoryName,
        [parameter(Mandatory = $true)] [String] $ResourceGroupName
    )

    [Synapse] $synapse = New-Object 'Synapse'
    $synapse.Name = $FactoryName
    $synapse.ResourceGroupName = $ResourceGroupName

    Stop-Triggers -synapse $synapse
    
}
