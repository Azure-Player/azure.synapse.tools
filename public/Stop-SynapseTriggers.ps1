<#
.SYNOPSIS
Stops all triggers in Synapse Workspace instance (service).

.DESCRIPTION
Stops (disables) all triggers in Synapse Workspace instance (service).

.PARAMETER SynapseWorkspace
Name of Synapse Workspace service to be affected.

.PARAMETER ResourceGroupName
Resource Group Name of Synapse Workspace service to be affected.

.EXAMPLE
$ResourceGroupName = 'rg-devops'
$SynapseWorkspace = "SQLPlayerSynapseDemo"
Stop-SynapseTriggers -SynapseWorkspace "$SynapseWorkspace" -ResourceGroupName "$ResourceGroupName"

.LINK
Online version: https://github.com/SQLPlayer/azure.synapse.tools/
#>
function Stop-SynapseTriggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $SynapseWorkspace,
        [parameter(Mandatory = $true)] [String] $ResourceGroupName
    )

    [Synapse] $synapse = New-Object 'Synapse'
    $synapse.Name = $SynapseWorkspace
    $synapse.ResourceGroupName = $ResourceGroupName

    Stop-Triggers -synapse $synapse
    
}
