function Stop-Trigger {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [parameter(Mandatory = $true)] [string] $SynapseWorkspaceName,
        [parameter(Mandatory = $true)] [string] $Name
    )

    Write-host "- Disabling trigger: $Name" 
    
    Stop-AzSynapseTrigger `
    -ResourceGroupName $ResourceGroupName `
    -WorkspaceName $SynapseWorkspaceName `
    -Name $Name `
    -Force | Out-Null

}
