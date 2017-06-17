[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'FileContentDsc' `
    -DscResourceName 'MSFT_ReplaceText' `
    -TestType 'Unit'

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope 'MSFT_ReplaceText' {
        #region Pester Test Initialization
        $script:testTextFile = 'TestFile.txt'
        $script:testText = 'TestText'
        $script:testSecret = 'TestSecret'
        $script:testSearch = "Setting\.Two='(.)*'"
        $script:testSearchNoFind = "Setting.NotExist='(.)*'"
        $script:testTextReplace = "Setting.Two='$($script:testText)'"
        $script:testSecretReplace = "Setting.Two='$($script:testSecret)'"
        $script:testSecureSecretReplace = ConvertTo-SecureString -String $script:testSecretReplace -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecretReplace)

        $script:testFileContent = @"
Setting1=Value1
Setting.Two='Value2'
Setting.Two='Value3'
Setting.Two='$($script:testText)'
Setting3.Test=Value4

"@

        $script:testFileExpectedTextContent = @"
Setting1=Value1
Setting.Two='$($script:testText)'
Setting.Two='$($script:testText)'
Setting.Two='$($script:testText)'
Setting3.Test=Value4

"@

        $script:testFileExpectedSecretContent = @"
Setting1=Value1
Setting.Two='$($script:testSecret)'
Setting.Two='$($script:testSecret)'
Setting.Two='$($script:testSecret)'
Setting3.Test=Value4

"@
        #endregion

        #region Function Get-TargetResource
        Describe 'MSFT_ReplaceText\Get-TargetResource' {
            Context 'File exists and search text can be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should Be $script:testTextFile
                    $script:result.Search | Should Be $script:testSearch
                    $script:result.Type   | Should Be 'Text'
                    $script:result.Text   | Should Be "$($script:testTextReplace),$($script:testTextReplace),$($script:testTextReplace)"
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can not be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearchNoFind `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should Be $script:testTextFile
                    $script:result.Search | Should Be $script:testSearchNoFind
                    $script:result.Type   | Should Be 'Text'
                    $script:result.Text   | Should BeNullOrEmpty
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_ReplaceText\Set-TargetResource' {
            Context 'File exists and search text can be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Set-Content `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($value -eq $script:testFileExpectedTextContent)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Text $script:testTextReplace `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Set-Content `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedTextContent)
                        } `
                        -Exactly 1
                }
            }

            Context 'File exists and search secret can be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Set-Content `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($value -eq $script:testFileExpectedSecretContent)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Type 'Secret' `
                        -Secret $script:testSecretCredential `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Set-Content `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedSecretContent)
                        } `
                        -Exactly 1
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_ReplaceString\Test-TargetResource' {
            Context 'File exists and search text can be found but does not match replace string' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Text $script:testTextReplace `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can be found and matches replace string' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Text $script:testTextReplace `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should return true' {
                    $script:result | Should Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can be found but does not match replace secret' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Type 'Secret' `
                        -Secret $script:testSecretCredential `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can be found and matches replace secret' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'MSFT_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedSecretContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Type 'Secret' `
                        -Secret $script:testSecretCredential `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should return true' {
                    $script:result | Should Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }
        }
        #endregion

        #region Function Assert-ParametersValid
        Describe 'MSFT_ReplaceText\Assert-ParametersValid' {
            Context 'File exists' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $true } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Assert-ParametersValid `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Verbose
                    } | Should Not Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Test-Path -Exactly 1
                }
            }

            Context 'File does not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $false } `
                    -Verifiable

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($localizedData.FileNotFoundError -f $script:testTextFile) `
                    -ArgumentName 'Path'

                It 'Should throw expected exception' {
                    { Assert-ParametersValid `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Verbose
                    } | Should Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Test-Path -Exactly 1
                }
            }
        }
        #endregion
    }
}
finally
{
    Exit-DscResourceTestEnvironment -TestEnvironment $script:testEnvironment
    Remove-Module -Name CommonTestHelper
}