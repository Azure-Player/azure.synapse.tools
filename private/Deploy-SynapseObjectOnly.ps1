function Deploy-SynapseObjectOnly {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [SynapseObject] $obj
    )
    Write-Debug "BEGIN: Deploy-SynapseObjectOnly(obj=$obj)"

    if ($obj.Deployed) { 
        Write-Verbose ("The object is already deployed.")
        return; 
    }
    #Write-Host "Deploying object: $($obj.Name) ($($obj.DependsOn.Count) dependency/ies)"
    #Write-Verbose "  Type: $($obj.Type)"
    $synapse = $obj.Synapse
    $ResourceGroupName = $synapse.ResourceGroupName
    $SynapseWorkspaceName = $synapse.Name

    $type = $obj.Type
    if ($type -eq 'SqlPool') {
        Write-Warning -Message 'Deployment of (dedicated) SqlPool is not supported, object must exist prior.'
        $obj.Deployed = $true;
        Write-Debug "END: Deploy-SynapseObjectOnly"
        return;
    }

    Write-Verbose ("Ready to deploy from file: {0}" -f $obj.FileName)
    $body = (Get-Content -Path $obj.FileName | Out-String)
    Write-Debug -Message $body
    $json = $body | ConvertFrom-Json

    if ($script:PublishMethod -eq "AzResource") { $type = "AzResource" }
    if ($obj.Type -in ('notebook', 'sqlscript', 'kqlscript', 'sparkJobDefinition')) { 
        $type = $obj.Type 
        Write-Warning "$($obj.Type)s are being deployed by Rest-API regardless of PublishMethod."
    }

    switch -Exact ($type)
    {
        'integrationRuntime'
        {
            Set-StrictMode -Version 1.0
            $desc = if ($null -eq $json.properties.description) { " " } else { $json.properties.description }
            if ($json.properties.type -eq "SelfHosted") {
                $linkedIR = $json.properties.typeProperties.linkedInfo

                if ($null -eq $linkedIR) {
                    Write-Verbose -Message "Integration Runtime type detected: Self-Hosted"
                    
                    Set-AzSynapseIntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    -Force | Out-Null
                } 
                else 
                {
                    Write-Verbose -Message "Integration Runtime type detected: Linked Self-Hosted"
                    Set-AzSynapseIntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -WorkspaceName $SynapseWorkspaceName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    -SharedIntegrationRuntimeResourceId $linkedIR.resourceId `
                    -Force | Out-Null
                }
            }
            elseif ($json.properties.type -eq "Managed") {
                Write-Verbose -Message "Integration Runtime type detected: Azure Managed"
                $computeIR = $json.properties.typeProperties.computeProperties
                $dfp = $computeIR.dataFlowProperties
                Set-AzSynapseIntegrationRuntime `
                -ResourceGroupName $ResourceGroupName `
                -WorkspaceName $SynapseWorkspaceName `
                -Name $json.name `
                -Type $json.properties.type `
                -Description $desc `
                -DataFlowComputeType $dfp.computeType `
                -DataFlowTimeToLive $dfp.timeToLive `
                -DataFlowCoreCount $dfp.coreCount `
                -Location $computeIR.location `
                -Force | Out-Null
            }
            else {
                Write-Error "Deployment for this kind of Integration Runtime is not supported yet."
            }
        }
        'linkedService'
        {
            Set-AzSynapseLinkedService `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'pipeline'
        {
            Set-AzSynapsePipeline `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'dataset'
        {
            # Set-AzSynapseDataset `
            # -WorkspaceName $SynapseWorkspaceName `
            # -Name $obj.Name `
            # -DefinitionFile $obj.FileName `
            # | Out-Null
            $h = Get-RequestHeader
            $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/datasets/$($obj.Name)?api-version=2020-12-01"
            $r = Invoke-RestMethod -Method PUT -Uri $uri -Body $body -Headers $h
            Wait-CompleteOperation -SynapseWorkspaceName $SynapseWorkspaceName -requestHeader $h -operationId $r.operationId -operation 'operationResults' | Out-Null
        }
        'dataflow'
        {
            Set-AzSynapseDataFlow `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'trigger'
        {
            Set-AzSynapseTrigger `
            -WorkspaceName $SynapseWorkspaceName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'kqlscript'
        {
            $h = Get-RequestHeader
            $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/kqlscripts/$($obj.Name)?api-version=2020-12-01"
            $r = Invoke-RestMethod -Method PUT -Uri $uri -Body $body -Headers $h
            Wait-CompleteOperation -SynapseWorkspaceName $SynapseWorkspaceName -requestHeader $h -operationId $r.operationId -operation 'operationResults' | Out-Null
        }
        'sqlscript'
        {
            $h = Get-RequestHeader
            $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/sqlscripts/$($obj.Name)?api-version=2020-12-01"
            $r = Invoke-RestMethod -Method PUT -Uri $uri -Body $body -Headers $h
            Wait-CompleteOperation -SynapseWorkspaceName $SynapseWorkspaceName -requestHeader $h -operationId $r.operationId -operation 'operationResults' | Out-Null
        }
        'notebook'
        {
            $h = Get-RequestHeader
            $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/notebooks/$($obj.Name)?api-version=2020-12-01"
            $r = Invoke-RestMethod -Method PUT -Uri $uri -Body $body -Headers $h
            Wait-CompleteOperation -SynapseWorkspaceName $SynapseWorkspaceName -requestHeader $h -operationId $r.operationId -operation 'notebookOperationResults' | Out-Null
        }
        'sparkJobDefinition'
        {
            $h = Get-RequestHeader
            $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/sparkJobDefinitions/$($obj.Name)?api-version=2020-12-01"
            $r = Invoke-RestMethod -Method PUT -Uri $uri -Body $body -Headers $h
            Wait-CompleteOperation -SynapseWorkspaceName $SynapseWorkspaceName -requestHeader $h -operationId $r.operationId -operation 'operationResults' | Out-Null
        }
        'AzResource'
        {
            $resType = Get-AzureResourceType $obj.Type

            Write-Verbose $resType
            Write-Verbose "$SynapseWorkspaceName/$($obj.Name)"

            New-AzResource `
            -ResourceType $resType `
            -ResourceGroupName $resourceGroupName `
            -Name "$SynapseWorkspaceName/$($obj.Name)" `
            -ApiVersion "2020-12-01" `
            -Properties $json `
            -IsFullObject -Force | Out-Null
        }






        default
        {
            Write-Error "Type $($obj.Type) is not supported."
        }
    }

    $obj.Deployed = $true;

    Write-Debug "END: Deploy-SynapseObjectOnly"

}
