#region Start-ProcessWithOutput
Function Start-ProcessWithOutput
  {
      <#
          .SYNOPSIS
          Allows for the execution of processes with the ability to return their output without first dumping the content to a file. It can all be kept in memory.
          
          .DESCRIPTION
          This is not the best option when your process returns a large enough amount of output to cause a memory leak or overflow.
          
          .PARAMETER FilePath
	        Your parameter description

          .PARAMETER WorkingDirectory
	        Your parameter description

          .PARAMETER ArgumentList
	        Your parameter description

          .PARAMETER AcceptableExitCodeList
	        A * can be used to accept all exit codes.

          .PARAMETER WindowStyle
	        Your parameter description

          .PARAMETER CreateNoWindow
	        Your parameter description

          .PARAMETER ParseOutput
	        Enables the parsing of the command output into objects.

          .PARAMETER ParsingExpression
	        A valid regular expression that will allow for the output to be parsed into objects.

          .PARAMETER LogOutput
	        Your parameter description
          
          .EXAMPLE
          Start-ProcessWithOutput -FilePath 'cmd.exe' -ArgumentList '/c ipconfig /all' -AcceptableExitCodeList @('*') -CreateNoWindow -WindowStyle 'Hidden' -LogOutput -Verbose

          .EXAMPLE
          $StartProcessWithOutputParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
	          $StartProcessWithOutputParameters.FilePath = "dsregcmd.exe"
	          $StartProcessWithOutputParameters.WorkingDirectory = "$([System.Environment]::SystemDirectory)"
	          $StartProcessWithOutputParameters.ArgumentList = New-Object -TypeName 'System.Collections.Generic.List[String]'
		          $StartProcessWithOutputParameters.ArgumentList.Add('/status')
	          $StartProcessWithOutputParameters.AcceptableExitCodeList = New-Object -TypeName 'System.Collections.Generic.List[String]'
		          $StartProcessWithOutputParameters.AcceptableExitCodeList.Add('0')
	          $StartProcessWithOutputParameters.WindowStyle = "Hidden"
	          $StartProcessWithOutputParameters.CreateNoWindow = $True
	          $StartProcessWithOutputParameters.ParseOutput = $True
	          $StartProcessWithOutputParameters.ParsingExpression = "(?:\s+)(?<PropertyName>.+)(?:\s+\:\s+)(?<PropertyValue>.+)"
	          $StartProcessWithOutputParameters.LogOutput = $True
	          $StartProcessWithOutputParameters.Verbose = $True

          $StartProcessWithOutputResult = Start-ProcessWithOutput @StartProcessWithOutputParameters

          Write-Output -InputObject ($StartProcessWithOutputResult)
  
          .NOTES
          Mileage may vary when parsing output and may have to be done using additional code outside of this function to address specific needs.
          
          .LINK
          Place any useful link here where your function or cmdlet can be referenced
      #>
      
      [CmdletBinding()] 
        Param
          (        
              [Parameter(Mandatory=$True)]
              [ValidateNotNullOrEmpty()]
              [String]$FilePath,

              [Parameter(Mandatory=$False)]
              [ValidateNotNullOrEmpty()]
              [String]$WorkingDirectory,
                
              [Parameter(Mandatory=$False)]
              [AllowEmptyCollection()]
              [AllowNull()]
              [String[]]$ArgumentList,

              [Parameter(Mandatory=$False)]
              [AllowEmptyCollection()]
              [AllowNull()]
              [String[]]$AcceptableExitCodeList,

              [Parameter(Mandatory=$False)]
              [ValidateNotNullOrEmpty()]
              [ValidateSet('Normal', 'Hidden', 'Minimized', 'Maximized')]
              [String]$WindowStyle,

              [Parameter(Mandatory=$False)]
              [Switch]$CreateNoWindow,

              [Parameter(Mandatory=$False, ParameterSetName = 'ParseOutput')]
              [Switch]$ParseOutput,
              
              [Parameter(Mandatory=$False, ParameterSetName = 'ParseOutput')]
              [ValidateNotNullOrEmpty()]
              [Alias('StandardOutputParsingExpression')]
              [Regex]$ParsingExpression,
              
              [Parameter(Mandatory=$False)]
              [Switch]$LogOutput
          )
                  
      Try
        {
            $DateTimeLogFormat = 'dddd, MMMM dd, yyyy @ hh:mm:ss.FFF tt'  ###Monday, January 01, 2019 @ 10:15:34.000 AM###
            [ScriptBlock]$GetCurrentDateTimeLogFormat = {(Get-Date).ToString($DateTimeLogFormat)}
            
            $DateTimeMessageFormat = 'MM/dd/yyyy HH:mm:ss.FFF'  ###03/23/2022 11:12:48.347###
            [ScriptBlock]$GetCurrentDateTimeMessageFormat = {(Get-Date).ToString($DateTimeMessageFormat)}
            
            $DateFileFormat = 'yyyyMMdd'  ###20190403###
            [ScriptBlock]$GetCurrentDateFileFormat = {(Get-Date).ToString($DateFileFormat)}
            
            $DateTimeFileFormat = 'yyyyMMdd_HHmmss'  ###20190403_115354###
            [ScriptBlock]$GetCurrentDateTimeFileFormat = {(Get-Date).ToString($DateTimeFileFormat)}
            
            $LoggingDetails = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'    
              $LoggingDetails.LogMessage = $Null
              $LoggingDetails.WarningMessage = $Null
              $LoggingDetails.ErrorMessage = $Null

            #Determine the date and time we executed the function
            $FunctionStartTime = (Get-Date)
            
            [String]$CmdletName = $MyInvocation.MyCommand.Name 
            
            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Function `'$($CmdletName)`' is beginning. Please Wait..."
            Write-Verbose -Message ($LoggingDetails.LogMessage)
      
            #Define Default Action Preferences
              $ErrorActionPreference = 'Stop'
              
            [String[]]$AvailableScriptParameters = (Get-Command -Name ($CmdletName)).Parameters.GetEnumerator() | Where-Object {($_.Value.Name -inotin $CommonParameterList)} | ForEach-Object {"-$($_.Value.Name):$($_.Value.ParameterType.Name)"}
            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Available Function Parameter(s) = $($AvailableScriptParameters -Join ', ')"
            Write-Verbose -Message ($LoggingDetails.LogMessage)

            [String[]]$SuppliedScriptParameters = $PSBoundParameters.GetEnumerator() | ForEach-Object {"-$($_.Key):$($_.Value.GetType().Name)"}
            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Supplied Function Parameter(s) = $($SuppliedScriptParameters -Join ', ')"
            Write-Verbose -Message ($LoggingDetails.LogMessage)

            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Execution of $($CmdletName) began on $($FunctionStartTime.ToString($DateTimeLogFormat))"
            Write-Verbose -Message ($LoggingDetails.LogMessage)

            #Set default parameter values (If necessary)
            Switch ($True)
              {
                  {([String]::IsNullOrEmpty($WindowStyle) -eq $True) -or ([String]::IsNullOrWhiteSpace($WindowStyle) -eq $True)}
                    {
                        [String]$WindowStyle = 'Hidden'
                    }

                  {([String]::IsNullOrEmpty($ParsingExpression) -eq $True) -or ([String]::IsNullOrWhiteSpace($ParsingExpression) -eq $True)}
                    {
                        [Regex]$ParsingExpression =  '(?:\s+)(?<PropertyName>.+)(?:\s+\:\s+)(?<PropertyValue>.+)'
                    }
              }
            
            $OutputObjectProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
              $OutputObjectProperties.ExitCode = $Null
              $OutputObjectProperties.ExitCodeAsHex = $Null
              $OutputObjectProperties.ExitCodeAsInteger = $Null
              $OutputObjectProperties.ExitCodeAsDecimal = $Null
              $OutputObjectProperties.ProcessObject = $Null
              $OutputObjectProperties.StandardOutput = $Null
              $OutputObjectProperties.StandardOutputObject = $Null
              $OutputObjectProperties.StandardError = $Null
              $OutputObjectProperties.StandardErrorObject = $Null
        
            $Process = New-Object -TypeName 'System.Diagnostics.Process'
              $Process.StartInfo.FileName = $FilePath
              $Process.StartInfo.UseShellExecute = $False          
              $Process.StartInfo.RedirectStandardOutput = $True
              $Process.StartInfo.RedirectStandardError = $True

            Switch ($True)
              {
                  {([String]::IsNullOrEmpty($WorkingDirectory) -eq $False) -and ([String]::IsNullOrWhiteSpace($WorkingDirectory) -eq $False)}
                    {
                        $Process.StartInfo.WorkingDirectory = $WorkingDirectory
                    }
              }
                  
            Switch ($CreateNoWindow.IsPresent)
              {
                  {($_ -eq $True)}
                    {
                        $Process.StartInfo.CreateNoWindow = ($CreateNoWindow.IsPresent)
                    }

                  Default
                    {
                        $Process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::$($WindowStyle)
                    }
              }

            Switch (($Null -ieq $AcceptableExitCodeList) -or ($AcceptableExitCodeList.Count -eq 0))
              {
                  {($_ -eq $True)}
                    {
                        $AcceptableExitCodeList = @()
                        
                        $AcceptableExitCodeList += '0'
                        $AcceptableExitCodeList += '3010'
                    }
              }
            
            Switch (($Null -ine $ArgumentList) -and ($ArgumentList.Count -gt 0))
              {
                  {($_ -eq $True)}
                    {
                        $Process.StartInfo.Arguments = $ArgumentList -Join ' '

                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to execute the following command: `"$($Process.StartInfo.FileName)`" $($Process.StartInfo.Arguments)"
                        Write-Verbose -Message ($LoggingDetails.LogMessage)
                    }

                  Default
                    {
                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to execute the following command: `"$($Process.StartInfo.FileName)`""
                        Write-Verbose -Message ($LoggingDetails.LogMessage)
                    }
              }
                            
            $Null = $Process.Start()
      
            $OutputObjectProperties.StandardOutput = $Process.StandardOutput.ReadToEnd()
            $OutputObjectProperties.StandardError = $Process.StandardError.ReadToEnd()
    
            $Null = $Process.WaitForExit()
           
            $OutputObjectProperties.ExitCode = $Process.ExitCode
            $OutputObjectProperties.ExitCodeAsHex = Try {'0x' + [System.Convert]::ToString($OutputObjectProperties.ExitCode, 16).PadLeft(8, '0').ToUpper()} Catch {$Null}
            $OutputObjectProperties.ExitCodeAsInteger = Try {$OutputObjectProperties.ExitCodeAsHex -As [Int]} Catch {$Null}
            $OutputObjectProperties.ExitCodeAsDecimal = Try {[System.Convert]::ToString($OutputObjectProperties.ExitCodeAsHex, 10)} Catch {$Null}

            $ExitCodeMessageList = New-Object -TypeName 'System.Collections.Generic.List[String]'
            
            $Null = $OutputObjectProperties.GetEnumerator() | Where-Object {($_.Key -imatch '(^ExitCode.*$)')} | Sort-Object -Property @('Key') | ForEach-Object {$ExitCodeMessageList.Add("[$($_.Key): $($_.Value)]")}
            
            $StartProcessExecutionTimespan = New-TimeSpan -Start ($Process.StartTime) -End ($Process.ExitTime)

            $OutputObjectProperties.ProcessObject = $Process
                                                                        
            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - The command execution took $($StartProcessExecutionTimespan.Hours.ToString()) hour(s), $($StartProcessExecutionTimespan.Minutes.ToString()) minute(s), $($StartProcessExecutionTimespan.Seconds.ToString()) second(s), and $($StartProcessExecutionTimespan.Milliseconds.ToString()) millisecond(s)."
            Write-Verbose -Message ($LoggingDetails.LogMessage)

            Switch (($AcceptableExitCodeList -icontains '*') -or ($OutputObjectProperties.ExitCode.ToString() -iin $AcceptableExitCodeList) -or ($OutputObjectProperties.ExitCodeAsHex.ToString() -iin $AcceptableExitCodeList) -or ($OutputObjectProperties.ExitCodeAsInteger.ToString() -iin $AcceptableExitCodeList) -or ($OutputObjectProperties.ExitCodeAsDecimal.ToString() -iin $AcceptableExitCodeList))
              {
                  {($_ -eq $True)}
                    {
                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - The command execution was successful. $($ExitCodeMessageList -Join ' ')"
                        Write-Verbose -Message ($LoggingDetails.LogMessage)
                    }

                  {($_ -eq $False)}
                    {
                        $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) -  The command execution was unsuccessful. $($ExitCodeMessageList -Join ' ')" 
                        Write-Warning -Message ($LoggingDetails.WarningMessage) -Verbose

                        $ErrorMessage = "$($LoggingDetails.WarningMessage)"
                        $Exception = [System.Exception]::New($ErrorMessage)           
                        $ErrorRecord = [System.Management.Automation.ErrorRecord]::New($Exception, [System.Management.Automation.ErrorCategory]::InvalidResult.ToString(), [System.Management.Automation.ErrorCategory]::InvalidResult, $Process)

                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                    }
              }
     
            Switch (($OutputObjectProperties.ExitCode.ToString() -iin $AcceptableExitCodeList) -or ($OutputObjectProperties.ExitCodeAsHex.ToString() -iin $AcceptableExitCodeList) -or ($OutputObjectProperties.ExitCodeAsInteger.ToString() -iin $AcceptableExitCodeList) -or ($OutputObjectProperties.ExitCodeAsDecimal.ToString() -iin $AcceptableExitCodeList))
              {
                  {($_ -eq $True)}
                    {
                        [String]$CommandContents = $OutputObjectProperties.StandardOutput
      
                        Switch (($ParseOutput.IsPresent -eq $True) -and ([String]::IsNullOrEmpty($ParsingExpression) -eq $False) -and ([String]::IsNullOrWhiteSpace($ParsingExpression) -eq $False))
                          {
                              {($_ -eq $True)}
                                {
                                    $RegexOptions = New-Object -TypeName 'System.Collections.Generic.List[System.Text.RegularExpressions.RegexOptions]'
                                      $RegexOptions.Add([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                                      $RegexOptions.Add([System.Text.RegularExpressions.RegexOptions]::Multiline)

                                    [System.Text.RegularExpressions.Regex]$RegularExpression = [System.Text.RegularExpressions.Regex]::New($ParsingExpression, $RegexOptions.ToArray())

                                    [String[]]$RegularExpressionGroups = $RegularExpression.GetGroupNames() | Where-Object {($_ -notin @('0'))}

                                    [System.Text.RegularExpressions.MatchCollection]$RegularExpressionMatches = $RegularExpression.Matches($CommandContents)

                                    $StandardOutputObjectProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
 
                                    For ($RegularExpressionMatchIndex = 0; $RegularExpressionMatchIndex -lt $RegularExpressionMatches.Count; $RegularExpressionMatchIndex++)
                                      {
                                          [System.Text.RegularExpressions.Match]$RegularExpressionMatch = $RegularExpressionMatches[$RegularExpressionMatchIndex]
      
                                          For ($RegularExpressionGroupIndex = 0; $RegularExpressionGroupIndex -lt $RegularExpressionGroups.Count; $RegularExpressionGroupIndex++)
                                            {
                                                [String]$RegularExpressionGroup = $RegularExpressionGroups[$RegularExpressionGroupIndex]

                                                Switch ($RegularExpressionGroup)
                                                  {
                                                      {($_ -imatch '(^PropertyName$)')}
                                                        {
                                                            $PropertyDetails = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                              $PropertyDetails.Add('Name', $Null)
                                                              $PropertyDetails.Add('Value', $Null)
                            
                                                            $PropertyDetails.Name = ($RegularExpressionMatch.Groups[$($RegularExpressionGroup)].Value) -ireplace '(\s+)|(\-)|(_)', ''
                                                        }
                    
                                                      {($_ -imatch '(^PropertyValue$)')}
                                                        {
                                                            $PropertyDetails.Value = $RegularExpressionMatch.Groups[$($RegularExpressionGroup)].Value
                                    
                                                            Switch ($True)
                                                              {
                                                                  {($PropertyDetails.Value -imatch '\+(\-){1,}\+')}
                                                                    {
                                                                        $PropertyDetails.Value = $Null
                                                                    }
                                            
                                                                  {($PropertyDetails.Value -imatch '(.+\,\s+.+){1,}')}
                                                                    {
                                                                        #$PropertyDetails.Value = $PropertyDetails.Value.Split(',').Trim()
                                                                    }
                                                                    
                                                                  {($PropertyDetails.Value -imatch '.+\(.+\).+')}
                                                                    {
                                                                        #$PropertyDetails.Value = ($PropertyDetails.Value.Split('()', [System.StringSplitOptions]::RemoveEmptyEntries) -ireplace 'bytes', '')[1]
                                                                    }
                                                              }
                                                  
                                                            Switch ($Null -ine $PropertyDetails.Value)
                                                              {
                                                                  {($_ -eq $True)}
                                                                    {
                                                                        $PropertyDetails.Value = $PropertyDetails.Value.Trim()
                                                                    }
                                                              }  
                                                        }
                                                  }    
                                            }

                                          Switch ($StandardOutputObjectProperties.Contains($PropertyDetails.Name))
                                            {
                                                {($_ -eq $False)}
                                                  {
                                                      $Null = $StandardOutputObjectProperties.Add($PropertyDetails.Name, $PropertyDetails.Value)
                                                  }
                                            }                 
                                      }
              
                                    $OutputObjectProperties.StandardOutputObject = New-Object -TypeName 'PSObject' -Property ($StandardOutputObjectProperties)
                                }
                          }      
                    }
              }
        }
      Catch
        {
            $ErrorMessageList = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
              $ErrorMessageList.Add('Message', $_.Exception.Message)
              $ErrorMessageList.Add('Category', $_.Exception.ErrorRecord.FullyQualifiedErrorID)
              $ErrorMessageList.Add('Script', $_.InvocationInfo.ScriptName)
              $ErrorMessageList.Add('LineNumber', $_.InvocationInfo.ScriptLineNumber)
              $ErrorMessageList.Add('LinePosition', $_.InvocationInfo.OffsetInLine)
              $ErrorMessageList.Add('Code', $_.InvocationInfo.Line.Trim())

            ForEach ($ErrorMessage In $ErrorMessageList.GetEnumerator())
              {
                  $LoggingDetails.ErrorMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) -  ERROR: $($ErrorMessage.Key): $($ErrorMessage.Value)"
                  Write-Warning -Message ($LoggingDetails.ErrorMessage) -Verbose
              }

            Throw "$($_.Exception.Message)"
        }
      Finally
        {
            #Dispose of the process object
              Try {$Null = $Process.Dispose()} Catch {}
            
            #Determine the date and time the function completed execution
              $FunctionEndTime = (Get-Date)

              $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Execution of $($CmdletName) ended on $($FunctionEndTime.ToString($DateTimeLogFormat))"
              Write-Verbose -Message ($LoggingDetails.LogMessage)

            #Log the total script execution time  
              $FunctionExecutionTimespan = New-TimeSpan -Start ($FunctionStartTime) -End ($FunctionEndTime)

              $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Function execution took $($FunctionExecutionTimespan.Hours.ToString()) hour(s), $($FunctionExecutionTimespan.Minutes.ToString()) minute(s), $($FunctionExecutionTimespan.Seconds.ToString()) second(s), and $($FunctionExecutionTimespan.Milliseconds.ToString()) millisecond(s)."
              Write-Verbose -Message ($LoggingDetails.LogMessage)
            
            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Function `'$($CmdletName)`' is completed."
            Write-Verbose -Message ($LoggingDetails.LogMessage)
          
            $OutputObject = New-Object -TypeName 'PSObject' -Property ($OutputObjectProperties)
            
            Switch (($LogOutput.IsPresent -eq $True) -or ($LogOutput -eq $True))
              {
                  {($_ -eq $True)}
                    {
                        ForEach ($Property In $OutputObject.PSObject.Properties)
                          {
                              Switch ($Property.Name)
                                {
                                    {($_ -iin @('StandardOutput', 'StandardError'))}
                                      {
                                          Switch (([String]::IsNullOrEmpty($Property.Value) -eq $False) -and ([String]::IsNullOrWhiteSpace($Property.Value) -eq $False))
                                            {
                                                {($_ -eq $True)}
                                                  {
                                                      $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - $($Property.Name): $($Property.Value)"
                                                      Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose
                                                  }
                                                  
                                                Default
                                                  {
                                                      $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - $($Property.Name): N/A"
                                                      Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose
                                                  }
                                            }
                                      }
                                }
                          }
                    }
              }
    
            Write-Output -InputObject ($OutputObject)
        }
  }
#endregion

<#
  $ProcessOutput = Start-ProcessWithOutput -FilePath 'dsregcmd.exe' -ArgumentList '/status' -CreateNoWindow -Verbose

  $ProcessOutput.StandardOutputObject | ConvertTo-JSON -Depth 10 -OutVariable 'AzureADDetails'

  $ProcessOutput
#>