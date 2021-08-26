function Get-SynapseObjectByName {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Synapse] $synapse,
        [parameter(Mandatory = $true)] [String] $name,
        [parameter(Mandatory = $true)] [String] $type
    )
    
    Write-Debug "BEGIN: Get-SynapseObjectByName(name=$name,type=$type)"

    $simtype = Get-SimplifiedType -Type "$type"
    switch -Exact ($simtype)
    {
        'IntegrationRuntime'
        {
            $r = $synapse.IntegrationRuntimes | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'LinkedService'
        {
            $r = $synapse.LinkedServices | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Pipeline'
        {
            $r = $synapse.Pipelines | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Dataset'
        {
            $r = $synapse.DataSets | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'DataFlow'
        {
            $r = $synapse.DataFlows | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'Trigger'
        {
            $r = $synapse.Triggers | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'SqlScript'
        {
            $r = $synapse.SqlScripts | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        'ManagedVirtualNetwork'
        {
            $r = $synapse.ManagedVirtualNetwork | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        }
        default
        {
            Write-Error "ASWT0014: Type [$type] is not supported."
        }
    }

    #$r = $synapse.AllObjects() | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    Write-Debug ($r | Format-List | Out-String)
    Write-Debug "END: Get-SynapseObjectByName()"
    return $r
}
