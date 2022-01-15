function Wait-CompleteOperation {
    param(
        [System.String]$SynapseWorkspaceName,
        [System.String]$operationId,
        $requestHeader,
        [ValidateSet('notebookOperationResults','operationResults')]
        $operation = 'operationResults'
    )

    Set-StrictMode -Version 1.0

    do {
        Write-Verbose "  Waiting 1500ms..."
        Start-Sleep -Seconds 1.5
        $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/$operation/$($operationId)?api-version=2020-12-01"
        $r = Invoke-RestMethod -Method GET -Uri $uri -Headers $requestHeader -Verbose:$false
        Write-Verbose "  Current status: $($r.Status)"
    } while (!($r.etag -or $r.Status -eq 'Failed'))
    if ($r.Status -eq 'Failed') { 
        Write-Host $r.error
        Write-Error "Failed publishing object:"
    } else {
        Write-Host "Completed."
        Write-Host $r
    }
}

