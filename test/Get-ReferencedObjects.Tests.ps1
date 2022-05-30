BeforeDiscovery {
    $ModuleRootPath = $PSScriptRoot | Split-Path -Parent
    $moduleManifestName = 'azure.synapse.tools.psd1'
    $moduleManifestPath = Join-Path -Path $ModuleRootPath -ChildPath $moduleManifestName
    
    Import-Module -Name $moduleManifestPath -Force -Verbose:$false
}

InModuleScope azure.synapse.tools {
    $testHelperPath = $PSScriptRoot | Join-Path -ChildPath 'TestHelper'
    Import-Module -Name $testHelperPath -Force

    # Variables for use in tests

    Describe 'Find-RefObject' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Find-RefObject -ErrorAction Stop } | Should -Not -Throw
        }
        It 'Should run' {
            [System.Collections.ArrayList] $arr = [System.Collections.ArrayList]::new()
            $script:ind = 0
            $node = '{ }' | ConvertFrom-Json
            Find-RefObject -node $node -list $arr
        }
    }

    Describe 'Get-ReferencedObjects' -Tag 'Unit' {
        It 'Should exist' {
            { Get-Command -Name Get-ReferencedObjects -ErrorAction Stop } | Should -Not -Throw
        }

        # Temporarly disabled as it returns different exception type depends on running environment
        # It 'Should return ArgumentNullException when no input param passes' {
        #     { Get-ReferencedObjects } | Should -Throw -ExceptionType 'System.ArgumentNullException'        # Return on local PC
        #     { Get-ReferencedObjects } | Should -Throw -ExceptionType 'System.Management.Automation.ParameterBindingException'   # Return on Agent DevOps
        # }

        $cases= @{ Adf = 'Synapse1'; Name = 'pipeline\pl_execute_notebook_cicd'; RefCount = 2},
                @{ Adf = 'Synapse1'; Name = 'pipeline\pl_execute_notebook_cicd_dynamic'; RefCount = 0}

        It 'Should find <RefCount> refs in object "<Adf>\<Name>"' -TestCases $cases {
            param
            (
                [string] $Adf,
                [string] $Name,
                [string] $RefCount
            )
            $script:RootFolder = "$PSScriptRoot\$Adf"
            $o = Get-SynapseObjectFromFile -FullPath "$($RootFolder)\$Name.json"
            $o | Should -Not -Be $null
            $VerbosePreference = 'Continue'
            $refs = Get-ReferencedObjects -obj $o
            @($refs).Count | Should -Be $RefCount
        }


    } 
}
