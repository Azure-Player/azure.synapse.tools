function Get-AzureResourceType {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [String] $Type
    )

    $resType = ""
    if ($type -like 'PS*') { $type = $type.Substring(2) }
    if ($type -like '*IntegrationRuntime') { $type = 'IntegrationRuntime' }

    switch -Exact ($type)
    {
        'integrationRuntime'    { $resType = 'Microsoft.Synapse/workspaces/integrationruntimes' }
        'pipeline'              { $resType = 'Microsoft.Synapse/workspaces/pipelines' }
        'dataset'               { $resType = 'Microsoft.Synapse/workspaces/datasets' }
        'dataflow'              { $resType = 'Microsoft.Synapse/workspaces/dataflows' }
        'linkedService'         { $resType = 'Microsoft.Synapse/workspaces/linkedservices' }
        'trigger'               { $resType = 'Microsoft.Synapse/workspaces/triggers' }
        'sqlscript'             { $resType = 'Microsoft.Synapse/workspaces/sqlscripts' }
        'factory'               { $resType = 'Microsoft.Synapse/workspaces' }
        default                 { Write-Error "Type '$Type' is not supported." }
    }

    return $resType
}