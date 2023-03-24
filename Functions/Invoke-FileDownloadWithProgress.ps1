## Microsoft Function Naming Convention: http://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx

#region Function Invoke-FileDownloadWithProgress
Function Invoke-FileDownloadWithProgress
    {
        <#
          .SYNOPSIS
          Downloads the specified URL.
          
          .DESCRIPTION
          The file will only be downloaded if the last modified date of the source URL is different from the last modified date of the file that has already been downloaded or if the file have not already been downloaded.
          
          .PARAMETER URL
          The URL where the file is located.

          .PARAMETER Destination
          The directory path where the URL will be downloaded to. If not specified, a default value will be used.

          .EXAMPLE
          Invoke-FileDownloadWithProgress -URL 'https://dl.dell.com/catalog/DriverPackCatalog.cab' -Destination "$($Env:ProgramData)\Dell\DriverPackCatalog" -FileName "DriverPackCatalog.cab" -Verbose

          .EXAMPLE
          $DownloadDetails = Invoke-FileDownloadWithProgress -URL 'https://dl.dell.com/catalog/DriverPackCatalog.cab' -Destination "$($Env:ProgramData)\Dell\DriverPackCatalog" -Verbose

          Write-Output -InputObject ($DownloadDetails)
          
          .EXAMPLE
          $InvokeFileDownloadWithProgressParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
	          $InvokeFileDownloadWithProgressParameters.URL = 'https://dl.dell.com/catalog/DriverPackCatalog.cab' -As [System.URI]
	          $InvokeFileDownloadWithProgressParameters.Destination = "$($Env:ProgramData)\Dell\DriverPackCatalog" -As [System.IO.DirectoryInfo]
            $InvokeFileDownloadWithProgressParameters.FileName = "DriverPackCatalog.cab"
	          $InvokeFileDownloadWithProgressParameters.ContinueOnError = $False
	          $InvokeFileDownloadWithProgressParameters.Verbose = $True

          $InvokeFileDownloadWithProgressResult = Invoke-FileDownloadWithProgress @InvokeFileDownloadWithProgressParameters

          Write-Output -InputObject ($InvokeFileDownloadWithProgressResult)
          
          .NOTES
          NEL               : {"report_to":"network-errors","max_age":3600}
          Report-To         : {"group":"network-errors","max_age":3600,"endpoints":[{"url":"https://www.dell.com/support/onlineapi/nellogger/log"}]}
          Accept-Ranges     : bytes
          Content-Type      : application/vnd.ms-cab-compressed
          ETag              : "8043933683ddd81:0"
          Last-Modified     : Tue, 11 Oct 2022 15:07:43 GMT
          Server            : Microsoft-IIS/10.0
          X-Powered-By      : ASP.NET
          x-arr-set         : arr4
          Content-Length    : 270867
          Date              : Thu, 20 Oct 2022 15:51:44 GMT
          Connection        : keep-alive
          Akamai-Request-BC : [a=23.207.199.174,b=78861523,c=g,n=US_VA_STERLING,o=20940]
          
          .LINK
          https://learn.microsoft.com/en-us/dotnet/api/system.net.webrequest?view=netframework-4.8
          
          .LINK
          https://learn.microsoft.com/en-us/dotnet/api/system.net.webclient.downloadfiletaskasync?view=netframework-4.8
        #>
        
        [CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess = $True)]
       
        Param
          (        
              [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True)]
              [ValidateNotNullOrEmpty()]
              [ValidatePattern('^http(s)\:\/\/.*\/.*\.(.{3,4})$')]
              [System.URI]$URL,
                
              [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True)]
              [ValidateNotNullOrEmpty()]
              [System.IO.DirectoryInfo]$Destination,

              [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $True)]
              [ValidateNotNullOrEmpty()]
              [ValidatePattern('^.*\.(.*)$')]
              [String]$FileName,
                                                            
              [Parameter(Mandatory=$False)]
              [Switch]$ContinueOnError        
          )
                    
        Begin
          {
              Try
                {
                    Switch ($True)
                      {
                          {([String]::IsNullOrEmpty($Destination) -eq $True) -or ([String]::IsNullOrWhiteSpace($Destination) -eq $True)}
                            {
                                [System.IO.DirectoryInfo]$Destination = "$($Env:Windir)\Temp"
                            }

                          {([String]::IsNullOrEmpty($FileName) -eq $True) -or ([String]::IsNullOrWhiteSpace($FileName) -eq $True)}
                            {
                                [String]$FileName = [System.IO.Path]::GetFileName($URL.OriginalString)
                            }
                      }

                    [System.IO.FileInfo]$DestinationPath = "$($Destination.FullName)\$($FileName)"
                    
                    $DateTimeLogFormat = 'dddd, MMMM dd, yyyy @ hh:mm:ss tt'  ###Monday, January 01, 2019 @ 10:15:34 AM###
                    [ScriptBlock]$GetCurrentDateTimeLogFormat = {(Get-Date).ToString($DateTimeLogFormat)}
                    $DateTimeMessageFormat = 'MM/dd/yyyy HH:mm:ss.FFF'  ###03/23/2022 11:12:48.347###
                    [ScriptBlock]$GetCurrentDateTimeMessageFormat = {(Get-Date).ToString($DateTimeMessageFormat)}
                    $DateFileFormat = 'yyyyMMdd'  ###20190403###
                    [ScriptBlock]$GetCurrentDateFileFormat = {(Get-Date).ToString($DateFileFormat)}
                    $DateTimeFileFormat = 'yyyyMMdd_HHmmss'  ###20190403_115354###
                    [ScriptBlock]$GetCurrentDateTimeFileFormat = {(Get-Date).ToString($DateTimeFileFormat)}
                    $TextInfo = (Get-Culture).TextInfo
                    $LoggingDetails = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'    
                      $LoggingDetails.Add('LogMessage', $Null)
                      $LoggingDetails.Add('WarningMessage', $Null)
                      $LoggingDetails.Add('ErrorMessage', $Null)
                    $CommonParameterList = New-Object -TypeName 'System.Collections.Generic.List[String]'
                      $CommonParameterList.AddRange([System.Management.Automation.PSCmdlet]::CommonParameters)
                      $CommonParameterList.AddRange([System.Management.Automation.PSCmdlet]::OptionalCommonParameters)

                    [ScriptBlock]$ErrorHandlingDefinition = {
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
                                                                      Write-Warning -Message ($LoggingDetails.ErrorMessage)
                                                                  }

                                                                Switch (($ContinueOnError.IsPresent -eq $False) -or ($ContinueOnError -eq $False))
                                                                  {
                                                                      {($_ -eq $True)}
                                                                        {                  
                                                                            Throw
                                                                        }
                                                                  }
                                                            }
                    
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

                    $OutputObjectProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                      $OutputObjectProperties.DownloadRequired = $False

                    #region Function Convert-FileSize
                    Function Convert-FileSize
                      {
                            <#
                              .SYSNOPSIS
                              Converts a size in bytes to its upper most value.

                              .PARAMETER Size
                              The size in bytes to convert

                              .EXAMPLE
                              $ConvertFileSizeParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
	                              $ConvertFileSizeParameters.Size = 4294964
	                              $ConvertFileSizeParameters.DecimalPlaces = 2

                              $ConvertFileSizeResult = Convert-FileSize @ConvertFileSizeParameters

                              Write-Output -InputObject ($ConvertFileSizeResult)

                              .EXAMPLE
                              $ConvertFileSizeResult = Convert-FileSize -Size 4294964

                              Write-Output -InputObject ($ConvertFileSizeResult)

                              .NOTES
                              Size              : 429496456565656
                              DecimalPlaces     : 0
                              Divisor           : 1099511627776
                              SizeUnit          : TB
                              SizeUnitAlias     : Terabytes
                              CalculatedSize    : 391
                              CalculatedSizeStr : 391 TB
                            #>
      
                          [CmdletBinding()]
                            Param
                              (
                                  [Parameter(Mandatory=$True)]
                                  [ValidateNotNullOrEmpty()]
                                  [Alias("Length")]
                                  $Size,

                                  [Parameter(Mandatory=$False)]
                                  [ValidateNotNullOrEmpty()]
                                  [Alias("DP")]
                                  [Int]$DecimalPlaces
                              )

                          Try
                            {
                                Switch ($True)
                                  {
                                      {([String]::IsNullOrEmpty($DecimalPlaces) -eq $True) -or ([String]::IsNullOrWhiteSpace($DecimalPlaces) -eq $True)}
                                        {
                                            [Int]$DecimalPlaces = 2
                                        }
                                  }
            
                                $OutputObjectProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                  $OutputObjectProperties.Size = $Size
                                  $OutputObjectProperties.DecimalPlaces = $DecimalPlaces
            
                                Switch ($Size)
                                  {
                                      {($_ -lt 1MB)}
                                        {  
                                            $OutputObjectProperties.Divisor = 1KB   
                                            $OutputObjectProperties.SizeUnit = 'KB'
                                            $OutputObjectProperties.SizeUnitAlias = 'Kilobytes'

                                            Break
                                        }

                                      {($_ -lt 1GB)}
                                        {
                                            $OutputObjectProperties.Divisor = 1MB  
                                            $OutputObjectProperties.SizeUnit = 'MB'
                                            $OutputObjectProperties.SizeUnitAlias = 'Megabytes'

                                            Break
                                        }

                                      {($_ -lt 1TB)}
                                        {
                                            $OutputObjectProperties.Divisor = 1GB   
                                            $OutputObjectProperties.SizeUnit = 'GB'
                                            $OutputObjectProperties.SizeUnitAlias = 'Gigabytes'

                                            Break
                                        }

                                      {($_ -ge 1TB)}
                                        {
                                            $OutputObjectProperties.Divisor = 1TB
                                            $OutputObjectProperties.SizeUnit = 'TB'
                                            $OutputObjectProperties.SizeUnitAlias = 'Terabytes'

                                            Break
                                        }
                                  }

                                $OutputObjectProperties.CalculatedSize = [System.Math]::Round(($Size / $OutputObjectProperties.Divisor), $OutputObjectProperties.DecimalPlaces)
                                $OutputObjectProperties.CalculatedSizeStr = "$($OutputObjectProperties.CalculatedSize) $($OutputObjectProperties.SizeUnit)"
                            }
                          Catch
                            {
                                Write-Error -Exception $_
                            }
                          Finally
                            {
                                $OutputObject = New-Object -TypeName 'PSObject' -Property ($OutputObjectProperties)

                                Write-Output -InputObject ($OutputObject)
                            }
                      }
                    #endregion
                }
              Catch
                {
                    $ErrorHandlingDefinition.Invoke()
                }
              Finally
                {
                    
                }
          }

        Process
          {           
              Try
                {  
                    $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to create a web request for `"$($URL.OriginalString)`". Please Wait..." 
                    Write-Verbose -Message ($LoggingDetails.LogMessage)
                                    
                    $WebRequest = [System.Net.WebRequest]::Create($URL.OriginalString)
                    
                    $WebRequestResponse = $WebRequest.GetResponse()
                    
                    $WebRequestResponseHeaders = $WebRequestResponse.Headers

                    $WebRequestHeaderProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'

                    ForEach ($WebRequestResponseHeader In $WebRequestResponseHeaders.AllKeys)
                      {      
                          $WebRequestHeaderProperties."$($WebRequestResponseHeader)" = ($WebRequestResponseHeaders.GetValues($WebRequestResponseHeader))[0]  
                      }

                    $WebRequestHeaders = New-Object -TypeName 'PSObject' -Property ($WebRequestHeaderProperties)

                    $WebRequestHeaders.'Last-Modified' = (Get-Date -Date $WebRequestHeaders.'Last-Modified').ToUniversalTime()

                    $ContentLengthInMB = [System.Math]::Round(($WebRequestHeaders.'Content-Length' / 1MB), 2)
                    
                    [ScriptBlock]$ExecuteDownload = {                                                                          
                                                        Try
                                                          {
                                                              $DownloadExecutionStopwatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'
                                                            
                                                              $WebClient = New-Object -TypeName 'System.Net.WebClient'
                                                                $WebClient.UseDefaultCredentials = $True

                                                              $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to download URL `"$($URL.OriginalString)`" to `"$($DestinationPath.FullName)`". Please Wait..."
                                                              Write-Verbose -Message ($LoggingDetails.LogMessage)

                                                              $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Download Size: $($ContentLengthInMB) MB"
                                                              Write-Verbose -Message ($LoggingDetails.LogMessage)
                                                              
                                                              If ([System.IO.Directory]::Exists($DestinationPath.Directory.FullName) -eq $False) {$Null = [System.IO.Directory]::CreateDirectory($DestinationPath.Directory.FullName)}

                                                              $Downloader = $WebClient.DownloadFileTaskAsync($URL.OriginalString, $DestinationPath.FullName)

                                                              $Null = Register-ObjectEvent -InputObject ($WebClient) -EventName 'DownloadProgressChanged' -SourceIdentifier 'WebClient.DownloadProgressChanged'

                                                              $Null = Start-Sleep -Seconds 3

                                                              $Null = $DownloadExecutionStopwatch.Start()

                                                              Switch ($Downloader.IsFaulted)
                                                                {
                                                                    {($_ -eq $True)}
                                                                      {
                                                                          $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - A download error has occured. Attempting to generate the error record. Please Wait..."
                                                                          Write-Warning -Message ($LoggingDetails.WarningMessage)

                                                                          Write-Error -Message ($Downloader.GetAwaiter().GetResult())
                                                                      }
                                                                }

                                                              While ($Downloader.IsCompleted -eq $False)
                                                                {
                                                                    Switch ($Downloader.IsFaulted)
                                                                      {
                                                                          {($_ -eq $True)}
                                                                            {
                                                                                $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - A download error has occured. Attempting to generate the error record. Please Wait..."
                                                                                Write-Warning -Message ($LoggingDetails.WarningMessage)

                                                                                Write-Error -Message ($Downloader.GetAwaiter().GetResult())

                                                                                Break
                                                                            }
                                                                      }
                                                                      
                                                                    $EventData = Get-Event -SourceIdentifier 'WebClient.DownloadProgressChanged' | Select-Object -ExpandProperty 'SourceEventArgs' -Last 1
                                                                    
                                                                    $EventDetails = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                      $EventDetails.Received = Convert-FileSize -Size ($EventData.BytesReceived) -DecimalPlaces 2
                                                                      $EventDetails.TotalToReceive = Convert-FileSize -Size ($EventData.TotalBytesToReceive) -DecimalPlaces 2
                                                                      $EventDetails.ProgressPercentage = $EventData.ProgressPercentage

                                                                    Switch ($DownloadExecutionStopwatch.Elapsed.Seconds -gt 0)
                                                                      {
                                                                          {($_ -eq $True)}
                                                                            {
                                                                                [Single]$TransferRate = [System.Math]::Round(($EventDetails.TotalToReceive.Size / $DownloadExecutionStopwatch.Elapsed.Seconds / 1MB), 2)
                                                                            }

                                                                          Default
                                                                            {
                                                                                [Single]$TransferRate = 0.00
                                                                            }
                                                                      }

                                                                    $WriteProgressParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                      $WriteProgressParameters.Activity = "Downloading `"$($DestinationPath.Name)`""
                                                                      $WriteProgressParameters.Status = "Completion Percentage: $($EventDetails.ProgressPercentage)%"
                                                                      $WriteProgressParameters.PercentComplete = $EventDetails.ProgressPercentage
                                                                      $WriteProgressParameters.CurrentOperation = "Downloaded $($EventDetails.Received.CalculatedSizeStr) of $($EventDetails.TotalToReceive.CalculatedSizeStr) @ $($TransferRate) Mbps"

                                                                    Write-Progress @WriteProgressParameters
                                                                }
                                                          }
                                                        Catch
                                                          {
                                                              Write-Error -Exception $_

                                                              $Null = Unregister-Event -SourceIdentifier 'WebClient.DownloadProgressChanged'

                                                              $Null = $DownloadExecutionStopwatch.Stop()

                                                              $Null = $DownloadExecutionStopwatch.Reset()

                                                              Break
                                                          }
                                                        Finally
                                                          {
                                                              $WriteProgressParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                $WriteProgressParameters.Activity = "Downloading `"$($DestinationPath.Name)`""
                                                                $WriteProgressParameters.Completed = $True

                                                              Write-Progress @WriteProgressParameters

                                                              $Null = Unregister-Event -SourceIdentifier 'WebClient.DownloadProgressChanged'

                                                              Switch (($Downloader.IsCompleted -eq $False) -or ($Downloader.IsFaulted -eq $True))
                                                                {
                                                                    {($_ -eq $True)}
                                                                      {
                                                                          $Null = $Downloader.CancelAsync()

                                                                          $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Download failed. Attempting to remove incomplete file `"$($DestinationPath.FullName)`". Please Wait..."
                                                                          Write-Warning -Message ($LoggingDetails.WarningMessage)

                                                                          $Null = [System.IO.File]::Delete($DestinationPath.FullName)
                                                                      }
                                                                }

                                                              $Null = $WebClient.Dispose()

                                                              $Null = $DownloadExecutionStopwatch.Stop()      
                                                          }
                                                                                                                                     
                                                        $DownloadExecutionTimespan = $DownloadExecutionStopwatch.Elapsed
                                                                                                                                     
                                                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Download completed in $($DownloadExecutionTimespan.Hours.ToString()) hour(s), $($DownloadExecutionTimespan.Minutes.ToString()) minute(s), $($DownloadExecutionTimespan.Seconds.ToString()) second(s), and $($DownloadExecutionTimespan.Milliseconds.ToString()) millisecond(s)."
                                                        Write-Verbose -Message ($LoggingDetails.LogMessage)

                                                        $Null = $DownloadExecutionStopwatch.Reset()
                                                                                        
                                                        [Int]$SecondsToWait = 3
                      
                                                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Pausing script execution for $($SecondsToWait) second(s). Please Wait..."
                                                        Write-Verbose -Message ($LoggingDetails.LogMessage)
                      
                                                        $Null = Start-Sleep -Seconds ($SecondsToWait)

                                                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to update the last modified date of `"$($DestinationPath.FullName)`" to match the last modified date of `"$($URL.OriginalString)`". Please Wait..."
                                                        Write-Verbose -Message ($LoggingDetails.LogMessage)

                                                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Last Modified Date UTC (Local File): $($DestinationPath.LastWriteTimeUTC.ToString($DateTimeLogFormat))"
                                                        Write-Verbose -Message ($LoggingDetails.LogMessage)

                                                        $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Last Modified Date UTC (URL Header): $($WebRequestHeaders.'Last-Modified'.ToString($DateTimeLogFormat))"
                                                        Write-Verbose -Message ($LoggingDetails.LogMessage)

                                                        $DestinationPathDetails = Get-Item -Path $DestinationPath.FullName -Force
                                                        
                                                        $Null = $DestinationPathDetails.LastWriteTimeUTC = $WebRequestHeaders.'Last-Modified'
                                                    }
 
                    Switch ([System.IO.File]::Exists($DestinationPath.FullName))
                      {
                          {($_ -eq $True)}
                            {
                                $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Destination path `"$($DestinationPath.FullName)`" already exists."
                                Write-Verbose -Message ($LoggingDetails.LogMessage)
                                
                                $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to check the last modified date of `"$($DestinationPath.FullName)`" to see if a download is necessary."
                                Write-Verbose -Message ($LoggingDetails.LogMessage)
                                
                                $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Last Modified Date UTC (Local File): $($DestinationPath.LastWriteTimeUTC.ToString($DateTimeLogFormat))"
                                Write-Verbose -Message ($LoggingDetails.LogMessage)

                                $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Last Modified Date UTC (URL Header): $($WebRequestHeaders.'Last-Modified'.ToString($DateTimeLogFormat))"
                                Write-Verbose -Message ($LoggingDetails.LogMessage)
                        
                                Switch (($DestinationPath.LastWriteTimeUTC -ine $WebRequestHeaders.'Last-Modified'))
                                  {
                                      {($_ -eq $True)}
                                        {
                                            $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - A redownload of `"$($URL.OriginalString)`" is necessary."
                                            Write-Warning -Message ($LoggingDetails.WarningMessage)

                                            $OutputObjectProperties.DownloadRequired = $True
                                    
                                            $ExecuteDownload.InvokeReturnAsIs()
                                        }

                                      Default
                                        {
                                            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - A redownload of `"$($URL.OriginalString)`" is not necessary."
                                            Write-Verbose -Message ($LoggingDetails.LogMessage)
                                        }
                                  }
                            }

                          Default
                            {
                                $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Destination path `"$($DestinationPath.FullName)`" does not exist."
                                Write-Warning -Message ($LoggingDetails.WarningMessage)
                                
                                $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - A download of `"$($URL.OriginalString)`" is necessary."
                                Write-Warning -Message ($LoggingDetails.WarningMessage)

                                $OutputObjectProperties.DownloadRequired = $True
                        
                                $ExecuteDownload.InvokeReturnAsIs()
                            }
                      } 
                }
              Catch
                {
                    $ErrorHandlingDefinition.Invoke()
                }
              Finally
                {
                    Try {$Null = $WebRequestResponse.Dispose()} Catch {}
                }
          }
        
        End
          {                                        
              Try
                {
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
                }
              Catch
                {
                    $ErrorHandlingDefinition.Invoke()
                }
              Finally
                {      
                    $DestinationPathDetails = Get-Item -Path $DestinationPath.FullName -Force
                    
                    $OutputObjectProperties.DownloadPath = $DestinationPathDetails
                    $OutputObjectProperties.URL = $URL
                    $OutputObjectProperties.URLHeaders = $WebRequestHeaders
                      
                    $OutputObject = New-Object -TypeName 'PSObject' -Property ($OutputObjectProperties)

                    Write-Output -InputObject ($OutputObject)
                }
          }
    }
#endregion