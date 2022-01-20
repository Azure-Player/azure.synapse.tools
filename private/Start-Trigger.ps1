function Start-Trigger {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [string] $SynapseWorkspaceName,
        [parameter(Mandatory = $true)] [string] $Name
    )

    # Start-AzSynapseTrigger `
    # -WorkspaceName $SynapseWorkspaceName `
    # -Name $Name `
    # | Out-Null

    # Currently the above code doesn't work: https://github.com/Azure/azure-powershell/issues/16368
    # Here is work around:
    $h = Get-RequestHeader
    $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/triggers/$($Name)/start?api-version=2020-12-01"
    Invoke-RestMethod -Method POST -Uri $uri -Headers $h | Out-Null

}
