BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.synapse.tools.psm1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.synapse.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    Describe 'Get-StateFromService' {
        Context 'Run test when throws an error' {
            BeforeAll {
                Mock -CommandName Get-AzStorageContainer -MockWith {}
            }
            $targetSynapse = [pscustomobject]@{
                name = 'synapse1'
            }
            It 'Should throw error if storage account does not exist' {
                {Get-StateFromService -targetSynapse $targetSynapse -StorageAccountName storage1} |Should -Throw
            }
            It 'Should throw error when container does not exist' {
                {Get-StateFromService -targetSynapse $targetSynapse -StorageAccountName storage1} |Should -Throw
            }
        }
        Context 'Run test when blob does not exist' {
            BeforeAll {
                $targetSynapse = [pscustomobject]@{
                    name = 'synapse1'
                }
                $CloudBlockBlobType = New-MockObject -Type Microsoft.Azure.Storage.Blob.CloudBlockBlob -Methods @{
                    Exists = {}
                    UploadText = {}
                    DownloadText = {
                        '{"Deployed":{}}'
                    }
                }  
                $CloudBlobContainerType = New-MockObject -Type Microsoft.Azure.Storage.Blob.CloudBlobContainer -Methods @{GetBlockBlobReference = {$CloudBlockBlobType}} 
                $Storage = New-MockObject -Type 'Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase' -Properties @{CloudBlobContainer = $CloudBlobContainerType}
                Mock -CommandName Get-AzStorageContainer -MockWith {
                    $Storage
                }
            }
            It 'Should create empty blob' {
                Mock -CommandName Write-Host -MockWith {'Created placeholder synapse1_deployment_state.json file'}
                $Result = Get-StateFromService -targetSynapse $targetSynapse -StorageAccountName 'storage1'
                Assert-MockCalled -CommandName Write-Host -Exactly -Times 1
                {$Result} |Should -Not -Throw
            }
        }
        Context 'Run test when return deployment state' {
            BeforeAll {
                $targetSynapse = [pscustomobject]@{
                    name = 'synapse1'
                }
                $CloudBlockBlobType = New-MockObject -Type Microsoft.Azure.Storage.Blob.CloudBlockBlob -Methods @{
                    Exists = {$true}
                    UploadText = {}
                    DownloadText = {
                        '{
                            "Deployed": {
                                "pipeline1": "ABCDE"
                            }
                        }'
                    }
                }  
                $CloudBlobContainerType = New-MockObject -Type Microsoft.Azure.Storage.Blob.CloudBlobContainer -Methods @{GetBlockBlobReference = {$CloudBlockBlobType}} 
                $Storage = New-MockObject -Type 'Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase' -Properties @{CloudBlobContainer = $CloudBlobContainerType}
                Mock -CommandName Get-AzStorageContainer -MockWith {
                    $Storage
                }
            }
            It 'Should exist' {
                {Get-Command -Name Get-StateFromService -ErrorAction Stop} | Should -Not -Throw
            }
            It 'Should return hashtable type' {
                Get-StateFromService -targetSynapse $targetSynapse -StorageAccountName 'storage1' | Should -BeOfType [hashtable]
            }
            It 'Should return ABCDE' {
                $State = Get-StateFromService -targetSynapse $targetSynapse -StorageAccountName 'storage1'
                $State.Values |Should -BeExactly 'ABCDE'
            }
        }
    }
}