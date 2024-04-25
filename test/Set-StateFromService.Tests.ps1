BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.synapse.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName

    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.synapse.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force
    Describe 'Set-StateFromService' {
        Context 'Run test when throws an error' {
            BeforeAll {
                Mock -CommandName Get-AzStorageContainer -MockWith {}
            }
            $targetSynapse = [pscustomobject]@{
                name = 'synapse1'
            }
            It 'Should throw error if storage account does not exist' {
                {Set-StateFromService -targetSynapse $targetSynapse -StorageAccountName storage1} |Should -Throw
            }
            It 'Should throw error when container does not exist' {
                {Set-StateFromService -targetSynapse $targetSynapse -StorageAccountName storage1} |Should -Throw
            }
        }
        Context 'Run test when return deployment state' {
            BeforeAll {
                $targetSynapse = [pscustomobject]@{
                    name = 'synapse1'
                }
                $CloudBlockBlobType = New-MockObject -Type Microsoft.Azure.Storage.Blob.CloudBlockBlob -Methods @{UploadText = {}}  
                $CloudBlobContainerType = New-MockObject -Type Microsoft.Azure.Storage.Blob.CloudBlobContainer -Methods @{GetBlockBlobReference = {$CloudBlockBlobType}} 
                $Storage = New-MockObject -Type 'Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase' -Properties @{CloudBlobContainer = $CloudBlobContainerType}
                Mock -CommandName Get-AzStorageContainer -MockWith {
                    $Storage
                }
            }
            It 'Should exist' {
                {Get-Command -Name Set-StateFromService -ErrorAction Stop} |Should -Not -Throw
            }
            It 'Should not throw' {
                {Set-StateFromService -targetSynapse $targetSynapse -StorageAccountName storage1} |Should -Not -Throw
            }
            It 'Should return success' {
                Set-StateFromService -targetSynapse $targetSynapse -StorageAccountName storage1 |Should -Be 'Successfully updated synapse1_deployment_state.json'
            }
        }
    }
}