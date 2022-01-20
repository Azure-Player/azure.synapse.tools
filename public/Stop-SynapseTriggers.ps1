<#
.SYNOPSIS
Stops all triggers in Synapse Workspace instance (service).

.DESCRIPTION
Stops (disables) all triggers in Synapse Workspace instance (service).

.PARAMETER SynapseWorkspace
Name of Synapse Workspace service to be affected.

.EXAMPLE
$SynapseWorkspace = "SQLPlayerSynapseDemo"
Stop-SynapseTriggers -SynapseWorkspace "$SynapseWorkspace"

.LINK
Online version: https://github.com/SQLPlayer/azure.synapse.tools/
#>
function Stop-SynapseTriggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $SynapseWorkspace
    )

    [Synapse] $synapse = New-Object 'Synapse'
    $synapse.Name = $SynapseWorkspace

    $synapse.PublishOptions = New-SynapsePublishOption
    Stop-Triggers -synapse $synapse
    
}
