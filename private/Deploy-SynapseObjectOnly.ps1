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
    $DataFactoryName = $synapse.Name

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
    # Global parameters is being deployed with different method:
    if ($obj.Type -eq "factory") { $type = "GlobalParameters" }

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
                    -DataFactoryName $DataFactoryName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    | Out-Null
                } 
                else 
                {
                    Write-Verbose -Message "Integration Runtime type detected: Linked Self-Hosted"
                    Set-AzSynapseIntegrationRuntime `
                    -ResourceGroupName $ResourceGroupName `
                    -DataFactoryName $DataFactoryName `
                    -Name $json.name `
                    -Type $json.properties.type `
                    -Description $desc `
                    -SharedIntegrationRuntimeResourceId $linkedIR.resourceId `
                    | Out-Null
                }
            }
            elseif ($json.properties.type -eq "Managed") {
                Write-Verbose -Message "Integration Runtime type detected: Azure Managed"
                $computeIR = $json.properties.typeProperties.computeProperties
                $dfp = $computeIR.dataFlowProperties
                Set-AzSynapseIntegrationRuntime `
                -ResourceGroupName $ResourceGroupName `
                -DataFactoryName $DataFactoryName `
                -Name $json.name `
                -Type $json.properties.type `
                -Description $desc `
                -DataFlowComputeType $dfp.computeType `
                -DataFlowTimeToLive $dfp.timeToLive `
                -DataFlowCoreCount $dfp.coreCount `
                -Location $computeIR.location `
                | Out-Null
            }
            else {
                Write-Error "Deployment for this kind of Integration Runtime is not supported yet."
            }
        }
        'linkedService'
        {
            Set-AzSynapseLinkedService `
            -WorkspaceName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'pipeline'
        {
            Set-AzSynapsePipeline `
            -WorkspaceName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'dataset'
        {
            Set-AzSynapseDataset `
            -WorkspaceName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'dataflow'
        {
            Set-AzSynapseDataFlow `
            -WorkspaceName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'trigger'
        {
            Set-AzSynapseTrigger `
            -WorkspaceName $DataFactoryName `
            -Name $obj.Name `
            -DefinitionFile $obj.FileName `
            | Out-Null
        }
        'sqlscript'
        {
            # Set-AzSynapseNotebook `
            # -WorkspaceName $DataFactoryName `
            # -Name $obj.Name `
            # -DefinitionFile $obj.FileName `
            # | Out-Null
            $token = Get-AzAccessToken -ResourceUrl 'https://dev.azuresynapse.net'
            $authHeader = @{
                'Content-Type'  = 'application/json'
                'Authorization' = 'Bearer ' + $token.Token
            }
            Invoke-RestMethod -Method PUT -Uri "https://$DataFactoryName.dev.azuresynapse.net/sqlscripts/$($obj.Name)?api-version=2020-12-01" -Body $body -Headers $authHeader
        }
        'AzResource'
        {
            $resType = Get-AzureResourceType $obj.Type

            Write-Verbose $resType
            Write-Verbose "$DataFactoryName/$($obj.Name)"

            New-AzResource `
            -ResourceType $resType `
            -ResourceGroupName $resourceGroupName `
            -Name "$DataFactoryName/$($obj.Name)" `
            -ApiVersion "2019-06-01-preview" `
            -Properties $json `
            -IsFullObject -Force | Out-Null
        }
        # 'GlobalParameters'
        # {
        #     $synapse.GlobalFactory.GlobalParameters = $json
        #     $synapse.GlobalFactory.body = $body
        #     Update-GlobalParameters -synapse $synapse -targetSynapse $targetSynapse
        # }
        default
        {
            Write-Error "Type $($obj.Type) is not supported."
        }
    }

    $obj.Deployed = $true;

    Write-Debug "END: Deploy-SynapseObjectOnly"

}
