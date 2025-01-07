function Get-SynapseObjectByPattern {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Synapse] $synapse,
        [parameter(Mandatory = $true)] [String] $name,
        [parameter(Mandatory = $true)] [String] $type
    )
    
    Write-Debug "BEGIN: Get-SynapseObjectByPattern(name=$name,type=$type)"

    $simtype = Get-SimplifiedType -Type "$type"
    switch -Exact ($simtype)
    {
        'IntegrationRuntime'
        {
            $r = $synapse.IntegrationRuntimes | Where-Object { $_.Name -like $name }
        }
        'LinkedService'
        {
            $r = $synapse.LinkedServices | Where-Object { $_.Name -like $name } 
        }
        'Pipeline'
        {
            $r = $synapse.Pipelines | Where-Object { $_.Name -like $name } 
        }
        'Dataset'
        {
            $r = $synapse.DataSets | Where-Object { $_.Name -like $name }
        }
        'DataFlow'
        {
            $r = $synapse.DataFlows | Where-Object { $_.Name -like $name } 
        }
        'Trigger'
        {
            $r = $synapse.Triggers | Where-Object { $_.Name -like $name } 
        }
        'SqlScript'
        {
            $r = $synapse.SqlScripts | Where-Object { $_.Name -like $name }
        }
        'Notebook'
        {
            $r = $synapse.Notebooks | Where-Object { $_.Name -eq $name }
        }
        'managedPrivateEndpoint'
        {
            $r = $synapse.ManagedPrivateEndpoints | Where-Object { $_.Name -like $name }
        }
        'managedVirtualNetwork\default\managedPrivateEndpoint'
        {
            $r = $synapse.ManagedPrivateEndpoints | Where-Object { $_.Name -like $name }
        }
        default
        {
            Write-Error "ASWT0015: Type [$type] is not supported."
        }
    }

    Write-Debug ($r | Format-List | Out-String)
    Write-Debug "END: Get-SynapseObjectByPattern()"
    return $r
}
