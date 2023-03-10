[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

$script:dscModuleName = 'DFSDsc'
$script:dscResourceName = 'DSC_DFSReplicationGroupFolder'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    # Ensure that the tests can be performed on this computer
    $productType = (Get-CimInstance Win32_OperatingSystem).ProductType
    Describe 'Environment' {
        Context 'Operating System' {
            It 'Should be a Server OS' {
                $productType | Should -Be 3
            }
        }
    }

    if ($productType -ne 3)
    {
        break
    }

    $featureInstalled = (Get-WindowsFeature -Name FS-DFS-Replication).Installed
    Describe 'Environment' {
        Context 'Windows Features' {
            It 'Should have the DFS Replication Feature Installed' {
                $featureInstalled | Should -BeTrue
            }
        }
    }

    if ($featureInstalled -eq $false)
    {
        break
    }

    InModuleScope $script:dscResourceName {
        # Create the Mock Objects that will be used for running tests
        $replicationGroup = [PSObject]@{
            GroupName = 'Test Group'
            Ensure = 'Present'
            DomainName = 'contoso.com'
            Description = 'Test Description'
            Members = @('FileServer1','FileServer2')
            Folders = @('Folder1','Folder2')
        }

        $mockReplicationGroupFolder = @(
            [PSObject]@{
                GroupName = $replicationGroup.GroupName
                DomainName = $replicationGroup.DomainName
                FolderName = $replicationGroup.Folders[0]
                Description = 'Description 1'
                FileNameToExclude = @('~*','*.bak','*.tmp')
                DirectoryNameToExclude = @()
                DfsnPath = "\\contoso.com\Namespace\$($replicationGroup.Folders[0])"
            },
            [PSObject]@{
                GroupName = $replicationGroup.GroupName
                DomainName = $replicationGroup.DomainName
                FolderName = $replicationGroup.Folders[1]
                Description = 'Description 2'
                FileNameToExclude = @('~*','*.bak','*.tmp')
                DirectoryNameToExclude = @()
                DfsnPath = "\\contoso.com\Namespace\$($replicationGroup.Folders[1])"
            }
        )

        Describe 'DSC_DFSReplicationGroupFolder\Get-TargetResource' {
            Context 'Replication group folder does not exist' {
                Mock Get-DfsReplicatedFolder

                It 'Should not throw error' {
                    {
                        $result = Get-TargetResource `
                            -GroupName $mockReplicationGroupFolder[0].GroupName `
                            -FolderName $mockReplicationGroupFolder[0].FolderName
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Requested replication group does exist' {
                Mock Get-DfsReplicatedFolder -MockWith { return @($mockReplicationGroupFolder[0]) }

                It 'Should return correct replication group' {
                    $result = Get-TargetResource `
                        -GroupName $mockReplicationGroupFolder[0].GroupName `
                        -FolderName $mockReplicationGroupFolder[0].FolderName
                    $result.GroupName | Should -Be $mockReplicationGroupFolder[0].GroupName
                    $result.FolderName | Should -Be $mockReplicationGroupFolder[0].FolderName
                    $result.Description | Should -Be $mockReplicationGroupFolder[0].Description
                    $result.DomainName | Should -Be $mockReplicationGroupFolder[0].DomainName
                    <#
                        Tests disabled until this issue is resolved:
                        https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/11088807-get-dscconfiguration-fails-with-embedded-cim-type
                    #>
                    if ($false) {
                        $result.FileNameToExclude | Should -Be $mockReplicationGroupFolder[0].FileNameToExclude
                        $result.DirectoryNameToExclude | Should -Be $mockReplicationGroupFolder[0].DirectoryNameToExclude
                    }
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DFSReplicationGroupFolder\Set-TargetResource' {
            Context 'Replication group folder exists but has different Description' {
                Mock Set-DfsReplicatedFolder

                It 'Should not throw error' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.Description = 'Different'
                    { Set-TargetResource @splat } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists but has different FileNameToExclude' {
                Mock Set-DfsReplicatedFolder

                It 'Should not throw error' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.FileNameToExclude = @('*.tmp')
                    { Set-TargetResource @splat } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists but has different DirectoryNameToExclude' {
                Mock Set-DfsReplicatedFolder

                It 'Should not throw error' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.DirectoryNameToExclude = @('*.tmp')
                    { Set-TargetResource @splat } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists but has different DfsnPath' {
                Mock Set-DfsReplicatedFolder

                It 'Should not throw error' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.DfsnPath = '\\contoso.com\Public\Different'
                    { Set-TargetResource @splat } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DFSReplicationGroupFolder\Test-TargetResource' {
            Context 'Replication group folder does not exist' {
                Mock Get-DfsReplicatedFolder

                It 'Should not throw error' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    { Test-TargetResource @splat } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists and has no differences' {
                Mock Get-DfsReplicatedFolder -MockWith { return @($mockReplicationGroupFolder[0]) }

                It 'Should return true' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    Test-TargetResource @splat | Should -BeTrue
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists but has different Description' {
                Mock Get-DfsReplicatedFolder -MockWith { return @($mockReplicationGroupFolder[0]) }

                It 'Should return false' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.Description = 'Different'
                    Test-TargetResource @splat | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists but has different FileNameToExclude' {
                Mock Get-DfsReplicatedFolder -MockWith { return @($mockReplicationGroupFolder[0]) }

                It 'Should return false' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.FileNameToExclude = @('*.tmp')
                    Test-TargetResource @splat | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists but has different DirectoryNameToExclude' {
                Mock Get-DfsReplicatedFolder -MockWith { return @($mockReplicationGroupFolder[0]) }

                It 'Should return false' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.DirectoryNameToExclude = @('*.tmp')
                    Test-TargetResource @splat | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }

            Context 'Replication group folder exists but has different DfsnPath' {
                Mock Get-DfsReplicatedFolder -MockWith { return @($mockReplicationGroupFolder[0]) }

                It 'Should return false' {
                    $splat = $mockReplicationGroupFolder[0].Clone()
                    $splat.DfsnPath = '\\contoso.com\Public\Different'
                    Test-TargetResource @splat | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
