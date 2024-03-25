<#
.SYNOPSIS
Loads all objects from Azure Synapse Workspace (service).

.DESCRIPTION
Loads all objects from Azure Synapse Workspace (service).

.PARAMETER WorkspaceName
Name of Azure Synapse Workspace service to be loaded.

.EXAMPLE
$WorkspaceName = "SQLPlayerDemo"
$synapseIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$synapseIns.AllObjects()

.LINK
Online version: https://github.com/SQLPlayer/azure.synapse.tools/
#>
function Get-SynapseFromService {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $WorkspaceName
    )
    Write-Debug "BEGIN: Get-SynapseromService(WorkspaceName=$WorkspaceName"

    $synapse = New-Object -TypeName Synapse
    $synapse.Name = $WorkspaceName

    $synapsei = Get-AzSynapseWorkspace -WorkspaceName "$WorkspaceName"
    Write-Host "Azure Synapse Workspace (instance) loaded."
    $synapse.Id = $synapsei.Id
    $synapse.Location = $synapsei.Location

    $synapse.Notebooks = Get-AzSynapseNotebook -WorkspaceName $WorkspaceName | ToArray
    Write-Host ("Notebooks: {0} object(s) loaded." -f $synapse.Notebooks.Count)
    $synapse.DataSets = Get-AzSynapseDataset -WorkspaceName $WorkspaceName | ToArray
    Write-Host ("DataSets: {0} object(s) loaded." -f $synapse.DataSets.Count)
    $synapse.IntegrationRuntimes = Get-AzSynapseIntegrationRuntime -WorkspaceName $WorkspaceName | ToArray
    Write-Host ("IntegrationRuntimes: {0} object(s) loaded." -f $synapse.IntegrationRuntimes.Count)
    $synapse.LinkedServices = Get-AzSynapseLinkedService -WorkspaceName $WorkspaceName | ToArray
    Write-Host ("LinkedServices: {0} object(s) loaded." -f $synapse.LinkedServices.Count)
    $synapse.Pipelines = Get-AzSynapsePipeline -WorkspaceName $WorkspaceName | ToArray
    Write-Host ("Pipelines: {0} object(s) loaded." -f $synapse.Pipelines.Count)
    $synapse.DataFlows = Get-AzSynapseDataFlow -WorkspaceName $WorkspaceName | ToArray
    Write-Host ("DataFlows: {0} object(s) loaded." -f $synapse.DataFlows.Count)
    $synapse.Triggers = Get-AzSynapseTrigger -WorkspaceName $WorkspaceName | ToArray
    Write-Host ("Triggers: {0} object(s) loaded." -f $synapse.Triggers.Count)


    Write-Debug "END: Get-AdfFromService()"
    return $synapse
}