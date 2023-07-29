<#
.SYNOPSIS
Reads all Synapse objects (JSON files) from pointed location and returns instance of [Synapse] class.

.DESCRIPTION
Reads all Synapse objects (JSON files) from pointed location and returns instance of [Synapse] class.

.PARAMETER SynapseWorkspaceName
Gives the name for created object of Synapse Workspace

.PARAMETER RootFolder
Location where all folders and JSON files are kept.

.EXAMPLE
$synapse = Import-SynapseFromFolder -SynapseWorkspaceName "SynWorkspace" -RootFolder "c:\GitHub\SynapseWrkName\"
IntegrationRuntimes: 4 object(s) loaded.
LinkedServices: 9 object(s) loaded.
Pipelines: 12 object(s) loaded.
DataSets: 26 object(s) loaded.
DataFlows: 7 object(s) loaded.
Triggers: 3 object(s) loaded.

.NOTES
Online version: https://github.com/Azure-Player/azure.synapse.tools/
#>
function Import-SynapseFromFolder {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [String] $SynapseWorkspaceName,
        [parameter(Mandatory = $true)] [String] $RootFolder
    )
    Write-Debug "BEGIN: Import-SynapseFromFolder(SynapseWorkspaceName=$SynapseWorkspaceName, RootFolder=$RootFolder)"

    Write-Verbose "Analyzing files of Synapse Workspace..."
    $synapse = New-Object -TypeName Synapse 
    $synapse.Name = $SynapseWorkspaceName

    if ( !(Test-Path -Path $RootFolder) ) { Write-Error "ASWT0019: Folder '$RootFolder' doesn't exist." }
    
    $synapse.Location = $RootFolder

    Import-SynapseObjects -Synapse $synapse -All $synapse.IntegrationRuntimes -RootFolder $RootFolder -SubFolder "integrationRuntime" | Out-Null
    Write-Host ("IntegrationRuntimes: {0} object(s) loaded." -f $synapse.IntegrationRuntimes.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.LinkedServices -RootFolder $RootFolder -SubFolder "linkedService" | Out-Null
    Write-Host ("LinkedServices: {0} object(s) loaded." -f $synapse.LinkedServices.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.Pipelines -RootFolder $RootFolder -SubFolder "pipeline" | Out-Null
    Write-Host ("Pipelines: {0} object(s) loaded." -f $synapse.Pipelines.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.DataSets -RootFolder $RootFolder -SubFolder "dataset" | Out-Null
    Write-Host ("DataSets: {0} object(s) loaded." -f $synapse.DataSets.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.DataFlows -RootFolder $RootFolder -SubFolder "dataflow" | Out-Null
    Write-Host ("DataFlows: {0} object(s) loaded." -f $synapse.DataFlows.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.Triggers -RootFolder $RootFolder -SubFolder "trigger" | Out-Null
    Write-Host ("Triggers: {0} object(s) loaded." -f $synapse.Triggers.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.SqlScripts -RootFolder $RootFolder -SubFolder "sqlscript" | Out-Null
    Write-Host ("SqlScripts: {0} object(s) loaded." -f $synapse.SqlScripts.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.KqlScripts -RootFolder $RootFolder -SubFolder "kqlscript" | Out-Null
    Write-Host ("KqlScripts: {0} object(s) loaded." -f $synapse.KqlScripts.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.Notebooks -RootFolder $RootFolder -SubFolder "notebook" | Out-Null
    Write-Host ("Notebooks: {0} object(s) loaded." -f $synapse.Notebooks.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.SparkJobDefinitions -RootFolder $RootFolder -SubFolder "sparkJobDefinition" | Out-Null
    Write-Host ("SparkJobDefinitions: {0} object(s) loaded." -f $synapse.SparkJobDefinitions.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.ManagedVirtualNetwork -RootFolder $RootFolder -SubFolder "managedVirtualNetwork" | Out-Null
    Write-Host ("Managed VNet: {0} object(s) loaded." -f $synapse.ManagedVirtualNetwork.Count)
    Import-SynapseObjects -Synapse $synapse -All $synapse.ManagedPrivateEndpoints -RootFolder $RootFolder -SubFolder "managedVirtualNetwork\default\managedPrivateEndpoint" | Out-Null
    Write-Host ("Managed Private Endpoints: {0} object(s) loaded." -f $synapse.ManagedPrivateEndpoints.Count)

    # A workaround of Microsoft's bug - no 'properties' in ManagedVirtualNetwork object
    if ($synapse.ManagedVirtualNetwork.Count -eq 1) {
        $o = $synapse.ManagedVirtualNetwork[0]
        if ($o.Body.PSobject.Properties.Name -notcontains "properties")
        {
            Write-Verbose 'Workaround: Addeding empty "properties" node to ManagedVirtualNetwork object...'
            Set-StrictMode -Version 1.0
            Add-ObjectProperty    -obj $o.Body -path 'properties.preventDataExfiltration' -value $false -ErrorAction 'Continue'
            Remove-ObjectProperty -obj $o.Body -path 'properties.preventDataExfiltration'               -ErrorAction 'Continue'
            $f = (Save-SynapseObjectAsFile -obj $o)
            $o.FileName = $f
        }
    }
    
    Write-Debug "END: Import-SynapseFromFolder()"
    return $synapse
}
