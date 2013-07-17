#region Set Config
function Set-ModuleConfig {
<#
.SYNOPSIS
    Sets module configuration parameters

.DESCRIPTION
    Sets module Configuration parameters from a file, into a globally scoped variable named after the module. 

.PARAMETER Name
    The name of the module to set the configuration for

.EXAMPLE
    At the top of a module run the following script:

    Set-ModuleConfig -Name $ExecutionContext.SessionState.Module -Verbose

.NOTES
    The best thing to do is define a powershell hash to contain the configuration variables and access like:
    $module_Config.config.someconfigitem
#>
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true)]
        [String]$Name
    )

    begin {
        Write-Verbose "Setting up"
        if ($module = Get-Module -Name $Name -ListAvailable) {
            $module_base_path = Split-Path -Path $module.Path
            $module_config_path = Join-Path -Path $module_base_path -ChildPath "$Name.config.ps1"
            $module_config_variable_name = "$Name`_Config"
        } else {
            throw "Cannot get module $Name"
        }
    }

    process {
        Write-Verbose "Testing module config file" 
        
        if ((Test-Path $module_config_path)) {
            Write-Verbose "Loading module config"

            try { 
            
                $config = @{
                    'config' = Invoke-Expression -Command $module_config_path
                    'config_error' = $false
                }
            }

            catch {
                $config = @{
                    'config_error' = $true
                    'config_error_message' = "Error executing config file $module_config_path"
                }
            }

        } else {
            $config = @{
                'config_error' = $true
                'config_error_message' = "Cannot find config file $module_config_path"
            }
        }
        
        Write-Verbose "Writing configuration hashtable into global level config variable"
        Set-Variable -Name $module_config_variable_name -Value $config -Scope Global
    }

    end {}
}
#endregion

#region Test
function Test-ModuleConfig {
<#
.SYNOPSIS
    Tests whether a module config is loaded or in error

.DESCRIPTION
    Tests whether a module config is loaded or in error

.PARAMETER Name
    The module config to test

.EXAMPLE
    Test-ModuleConfig SomeModuleName
#>
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true)]
        [String]$Name
    )

    begin {
        Write-Verbose "Setting up"
        $module = Get-Module -Name $Name
        $module_config_variable_name = "$Name`_Config"
    }

    process {
        Write-Verbose "Checking for error status"
        if ((Get-Variable -Scope Global -Name $module_config_variable_name).Value.config_error) {
            $false
        } else {
            $true
        }
    }

    end {}
}
#endregion

