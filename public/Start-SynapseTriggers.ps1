<#
.SYNOPSIS
Starts (enables) all triggers in Synapse Workspace instance (service).

.DESCRIPTION
Starts (enables) all triggers in Synapse Workspace instance (service).

.PARAMETER SynapseWorkspace
Name of Synapse Workspace service to be affected.

.EXAMPLE
$SynapseWorkspace = "SQLPlayerSynapseDemo"
Start-SynapseTriggers -SynapseWorkspace "$SynapseWorkspace"

.LINK
Online version: https://github.com/Azure-Player/azure.synapse.tools/
#>
function Start-SynapseTriggers {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $SynapseWorkspace
    )

    [Synapse] $synapse = New-Object 'Synapse'
    $synapse.Name = $SynapseWorkspace

    Write-Host "Getting all triggers from Synapse instance..."
    $triggers = Get-AzSynapseTrigger -WorkspaceName $SynapseWorkspace

    $triggers | ForEach-Object {
        $body = ConvertTo-Json $t0 -Depth 10 | ConvertFrom-Json     # In order to remove ReadOnly flag from runtimeState
        $body.properties.runtimeState = 'Started'   # Desired state
        $o = New-Object -TypeName 'SynapseObject'
        $o.Name = $_.Name
        $o.Type = 'trigger'
        $o.Body = $body
        $synapse.Triggers.Add($o) | Out-Null
    }

    $synapse.PublishOptions = New-SynapsePublishOption
    Start-Triggers -synapse $synapse
    
}
