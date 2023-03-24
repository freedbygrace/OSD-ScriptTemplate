## Microsoft Function Naming Convention: http://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx

#region Function Copy-ItemWithProgress
Function Copy-ItemWithProgress
    {
        <#
          .SYNOPSIS
          Copies file(s) from a valid path in segments.
          
          .DESCRIPTION
          Supports the copying of files from a valid location in segments either directly or recursively.
          Supports the usage of filters and exclusions exactly the way that the Get-ChildItem or Copy-Item cmdlets work.
          
          .PARAMETER Path
          A valid file or folder location.

          .PARAMETER Destination
          The destination directory where the content will be copied.

          .PARAMETER Include
          One or more filter(s) to implicitly copy what is specified.

          .PARAMETER Exclude
          One or more filter(s) to implicitly skip the copying of what is specified.

          .PARAMETER Recurse
          Recurse through the specified directories.

          .PARAMETER Force
          Overwrite file(s) that have already been copied. The default behavior is to skip the copying of the file.

          .PARAMETER SegmentSize
          The segment size in megabytes that each file will be transferred with.

          .PARAMETER RandomDelay
          Adds a pulse in between the transfer of each segment.

          .PARAMETER ContinueOnError
          Continues processing even if an error has occured.
          
          .EXAMPLE
          Copy-ItemWithProgress -Path 'FileOrDirectoryPath' -Destination 'YourDestinationDirectory' -Verbose

          .EXAMPLE
          $CopyItemWithProgressParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
            $CopyItemWithProgressParameters.Path = "FileOrDirectoryPath"
            $CopyItemWithProgressParameters.Destination = "YourDestinationDirectory"
            $CopyItemWithProgressParameters.Include = New-Object -TypeName 'System.Collections.Generic.List[String]'
              $CopyItemWithProgressParameters.Include.Add('*.*')
            $CopyItemWithProgressParameters.Exclude = New-Object -TypeName 'System.Collections.Generic.List[String]'
              $CopyItemWithProgressParameters.Exclude.Add('*.ini')
            $CopyItemWithProgressParameters.Recurse = $True
            $CopyItemWithProgressParameters.Force = $False
            $CopyItemWithProgressParameters.SegmentSize = 4096
            $CopyItemWithProgressParameters.RandomDelay = $False
            $CopyItemWithProgressParameters.ContinueOnError = $False
            $CopyItemWithProgressParameters.Verbose = $True

          $CopyItemWithProgressResult = Copy-ItemWithProgress @CopyItemWithProgressParameters

          Write-Output -InputObject ($CopyItemWithProgressResult)
  
          .NOTES
          A progress bar is displayed and can be useful for scripts where the copying of large file(s) is taking place.

          .LINK
          http://stackoverflow.com/questions/2434133/progress-during-large-file-copy-copy-item-write-progress
          
          .LINK
          https://stackoverflow.com/questions/13883404/custom-robocopy-progress-bar-in-powershell
        #>
        
        [CmdletBinding()]
       
        Param
          (        
                [Parameter(Mandatory=$True)]
                [ValidateNotNullOrEmpty()]
                [ValidateScript({Test-Path -Path $_})]
                [Alias('P')]
                [String]$Path,

                [Parameter(Mandatory=$True)]
                [ValidateNotNullOrEmpty()]
                [Alias('D')]
                [System.IO.DirectoryInfo]$Destination,

                [Parameter(Mandatory=$False)]
                [Alias('I')]
                [String[]]$Include,

                [Parameter(Mandatory=$False)]
                [Alias('E')]
                [String[]]$Exclude,
                
                [Parameter(Mandatory=$False)]
                [Alias('R')]
                [Switch]$Recurse,

                [Parameter(Mandatory=$False)]
                [Alias('Overwrite')]
                [Switch]$Force,

                [Parameter(Mandatory=$False)]
                [ValidateNotNullOrEmpty()]
                [Alias('SS', 'BufferInMegabytes')]
                [Int]$SegmentSize,

                [Parameter(Mandatory=$False)]
                [Alias('RD')]
                [Switch]$RandomDelay,
                                                    
                [Parameter(Mandatory=$False)]
                [Alias('COE')]
                [Switch]$ContinueOnError        
          )
                    
        Begin
          {

              
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
                    $TextInfo = (Get-Culture).TextInfo
                    $LoggingDetails = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'    
                      $LoggingDetails.Add('LogMessage', $Null)
                      $LoggingDetails.Add('WarningMessage', $Null)
                      $LoggingDetails.Add('ErrorMessage', $Null)
                    $CommonParameterList = New-Object -TypeName 'System.Collections.Generic.List[String]'
                      $CommonParameterList.AddRange([System.Management.Automation.PSCmdlet]::CommonParameters)
                      $CommonParameterList.AddRange([System.Management.Automation.PSCmdlet]::OptionalCommonParameters)
                    $FileSystemObject = New-Object -ComObject 'Scripting.FileSystemObject'

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
                    
                    [String]$FunctionName = $MyInvocation.MyCommand
                    [System.IO.FileInfo]$InvokingScriptPath = $MyInvocation.PSCommandPath
                    [System.IO.DirectoryInfo]$InvokingScriptDirectory = $InvokingScriptPath.Directory.FullName
                    [System.IO.FileInfo]$FunctionPath = "$($InvokingScriptDirectory.FullName)\Functions\$($FunctionName).ps1"
                    [System.IO.DirectoryInfo]$FunctionDirectory = "$($FunctionPath.Directory.FullName)"
                    
                    $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Function `'$($FunctionName)`' is beginning. Please Wait..."
                    Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose
              
                    #Define Default Action Preferences
                      $ErrorActionPreference = 'Stop'
                      
                    [String[]]$AvailableScriptParameters = (Get-Command -Name ($FunctionName)).Parameters.GetEnumerator() | Where-Object {($_.Value.Name -inotin $CommonParameterList)} | ForEach-Object {"-$($_.Value.Name):$($_.Value.ParameterType.Name)"}
                    $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Available Function Parameter(s) = $($AvailableScriptParameters -Join ', ')"
                    Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose

                    [String[]]$SuppliedScriptParameters = $PSBoundParameters.GetEnumerator() | ForEach-Object {"-$($_.Key):$($_.Value.GetType().Name)"}
                    $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Supplied Function Parameter(s) = $($SuppliedScriptParameters -Join ', ')"
                    Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose

                    $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Execution of $($FunctionName) began on $($FunctionStartTime.ToString($DateTimeLogFormat))"
                    Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose

                    #region Load any required libraries
                      [System.IO.DirectoryInfo]$LibariesDirectory = "$($FunctionDirectory.FullName)\Libraries"

                      Switch ([System.IO.Directory]::Exists($LibariesDirectory.FullName))
                        {
                            {($_ -eq $True)}
                              {
                                  $LibraryPatternList = New-Object -TypeName 'System.Collections.Generic.List[String]'
                                    #$LibraryPatternList.Add('')

                                  Switch ($LibraryPatternList.Count -gt 0)
                                    {
                                        {($_ -eq $True)}
                                          {
                                              $LibraryList = Get-ChildItem -Path ($LibariesDirectory.FullName) -Include ($LibraryPatternList.ToArray()) -Recurse -Force | Where-Object {($_ -is [System.IO.FileInfo])}

                                              $LibraryListCount = ($LibraryList | Measure-Object).Count
            
                                              Switch ($LibraryListCount -gt 0)
                                                {
                                                    {($_ -eq $True)}
                                                      {
                                                          For ($LibraryListIndex = 0; $LibraryListIndex -lt $LibraryListCount; $LibraryListIndex++)
                                                            {
                                                                $Library = $LibraryList[$LibraryListIndex]
            
                                                                [Byte[]]$LibraryBytes = [System.IO.File]::ReadAllBytes($Library.FullName)
            
                                                                $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to load assembly `"$($Library.FullName)`". Please Wait..."
                                                                Write-Verbose -Message ($LoggingDetails.LogMessage)
            
                                                                $Null = [System.Reflection.Assembly]::Load($LibraryBytes)     
                                                            }
                                                      }
                                                }
                                          }
                                    }      
                              }
                        }
                    #endregion

                    #region Set Default Parameter Values
                        Switch ($True)
                          {
                              {($Null -ieq $SegmentSize) -or ($SegmentSize -eq 0)}
                                {
                                    [Int]$SegmentSize = 8192
                                }
                          }
                    #endregion
                                        
                    #Create an object that will contain the functions output.
                      $OutputObjectList = New-Object -TypeName 'System.Collections.Generic.List[PSObject]'
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
                    Switch ($Null -ine $Path)
                      {
                          {($_ -eq $True)}
                            {                                            
                                $GetChildItemParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                    $GetChildItemParameters.Path = $Path
                                    $GetChildItemParameters.Force = $True    
                                    $GetChildItemParameters.ErrorAction = [System.Management.Automation.Actionpreference]::SilentlyContinue
            
                                Switch ($True)
                                  {
                                      {([String]::IsNullOrEmpty($Include) -eq $False) -and ([String]::IsNullOrWhiteSpace($Include) -eq $False)}
                                        {
                                            $GetChildItemParameters.Include = $Include
                                            
                                            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - File(s) matching $($GetChildItemParameters.Include -Join ', ') will be included." 
                                            Write-Verbose -Message ($LoggingDetails.LogMessage)      
                                        }
          
                                      {([String]::IsNullOrEmpty($Exclude) -eq $False) -and ([String]::IsNullOrWhiteSpace($Exclude) -eq $False)}
                                        {
                                            $GetChildItemParameters.Exclude = $Exclude
        
                                            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - File(s) matching $($GetChildItemParameters.Exclude -Join ', ') will be excluded." 
                                            Write-Verbose -Message ($LoggingDetails.LogMessage)
                                        }
          
                                      {($Recurse.IsPresent -eq $True)}
                                        {
                                            $GetChildItemParameters.Recurse = $True
        
                                            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - The search will be performed recursively." 
                                            Write-Verbose -Message ($LoggingDetails.LogMessage)
                                        }
                                  }

                                $FileList = Get-ChildItem @GetChildItemParameters | Where-Object {($_ -is [System.IO.FileInfo])}

                                $FileListDetails = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                  $FileListDetails.Count = ($FileList | Measure-Object).Count

                                Switch ($FileListDetails.Count -gt 0)
                                  {
                                      {($_ -eq $True)}
                                        {
                                            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - $($FileListDetails.Count) file(s) will be copied in $($SegmentSize) MB segments to the destination directory of `"$($Destination.FullName)`". Please Wait..." 
                                            Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose

                                            $FileListDetails.TotalBytes = ($FileList | Measure-Object -Sum 'Length').Sum
                                            $FileListDetails.TransferredBytes = 0
                                            $FileListDetails.PercentComplete = 0

                                            $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - A total of $([System.Math]::Round(($FileListDetails.TotalBytes / 1MB), 2)) MB needs to be transferred." 
                                            Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose
                                          
                                            $StopWatchTable = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                              $StopWatchTable.Primary = New-Object -TypeName 'System.Diagnostics.Stopwatch'
                                              $StopWatchTable.Secondary = New-Object -TypeName 'System.Diagnostics.Stopwatch'

                                            $Null = $StopWatchTable.Primary.Start()
                                          
                                            For ($FileListIndex = 0; $FileListIndex -lt $FileListDetails.Count; $FileListIndex++)
                                              {      
                                                  Try
                                                    {                                                      
                                                        $FileObjectProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                          $FileObjectProperties.Source = ($FileList[$FileListIndex]) -As [System.IO.FileInfo]
                                                          
                                                        Switch ($Recurse.IsPresent)
                                                          {
                                                              {($_ -eq $True)}
                                                                {
                                                                    $FileObjectProperties.SourceSegmentList = $FileObjectProperties.Source.FullName.Replace($Path, '').Split('\', [System.StringSplitOptions]::RemoveEmptyEntries) -As [System.Collections.Generic.List[String]]
                                                                            
                                                                    $FileObjectProperties.Destination = (Join-Path -Path ($Destination.FullName) -ChildPath ($FileObjectProperties.SourceSegmentList -Join '\')) -As [System.IO.FileInfo]
        
                                                                    $FileObjectProperties.Remove('SourceSegmentList')
                                                                }

                                                              Default
                                                                {
                                                                    $FileObjectProperties.Destination = "$($Destination.FullName)\$($FileObjectProperties.Source.Name)" -As [System.IO.FileInfo]
                                                                }
                                                          }
      
                                                        Switch ($True)
                                                          {
                                                              {([System.IO.Directory]::Exists($FileObjectProperties.Destination.Directory.FullName) -eq $False)}
                                                                {
                                                                    $Null = [System.IO.Directory]::CreateDirectory($FileObjectProperties.Destination.Directory.FullName)
                                                                }
                                                          }
                        
                                                        Switch (([System.IO.File]::Exists($FileObjectProperties.Destination.FullName) -eq $False) -or ($Force.IsPresent -eq $True))
                                                          {
                                                              {($_ -eq $True)}
                                                                {
                                                                    $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to copy `"$($FileObjectProperties.Source.FullName)`" to `"$($FileObjectProperties.Destination.FullName)`". Please Wait..." 
                                                                    Write-Verbose -Message ($LoggingDetails.LogMessage)
                                                                  
                                                                    $FileDetails = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                      $FileDetails.Source = [System.IO.File]::OpenRead($FileObjectProperties.Source.FullName)
                                                                      $FileDetails.Destination = [System.IO.File]::Create($FileObjectProperties.Destination.FullName)
                                                                      $FileDetails.Buffer = New-Object -TypeName 'Byte[]' -ArgumentList ($SegmentSize * 1024)
                                                                      $FileDetails.SegmentBytes = 0
                                                                      $FileDetails.TransferredBytes = 0
                                                                      $FileDetails.Number = $FileListIndex + 1
                                                                      
                                                                    $Null = $StopWatchTable.Secondary.Start()
     
                                                                    Do
                                                                      {
                                                                          $FileDetails.SegmentBytes = $FileDetails.Source.Read($FileDetails.Buffer, 0, $FileDetails.Buffer.Length)

                                                                          $FileDetails.Destination.Write($FileDetails.Buffer, 0, $FileDetails.SegmentBytes)

                                                                          $FileDetails.TransferredBytes = $FileDetails.TransferredBytes + $FileDetails.SegmentBytes

                                                                          $FileListDetails.TransferredBytes = $FileListDetails.TransferredBytes + $FileDetails.SegmentBytes

                                                                          Switch ($FileDetails.Source.Length -gt 1)
                                                                            {
                                                                                {($_ -eq $True)}
                                                                                  {
                                                                                      $FileDetails.PercentComplete = (($FileDetails.TransferredBytes / $FileDetails.Source.Length) * 100) -As [Int]      
                                                                                  }

                                                                                Default
                                                                                  {
                                                                                      $FileDetails.PercentComplete = (100) -As [Int]
                                                                                  }
                                                                            }

                                                                          $FileDetails.PercentComplete = [System.Math]::Round($FileDetails.PercentComplete, 2)

                                                                          $FileDetails.TotalSecondsElasped = $StopWatchTable.Secondary.Elapsed.TotalSeconds -As [Int]

                                                                          Switch ($FileDetails.TotalSecondsElasped -ne 0)
                                                                            {
                                                                                {($_ -eq $True)}
                                                                                  {
                                                                                      $FileDetails.TransferRate = ($FileDetails.TransferredBytes / $FileDetails.TotalSecondsElasped / 1MB) -As [Single]
                                                                                  }

                                                                                Default
                                                                                  {
                                                                                      $FileDetails.TransferRate = (0.0) -As [Single]
                                                                                  }
                                                                            }

                                                                          $FileDetails.TransferRate = [System.Math]::Round($FileDetails.TransferRate, 2)

                                                                          Switch (($Total % 1MB) -eq 0)
                                                                            {
                                                                                {($_ -eq $True)}
                                                                                  {
                                                                                      Switch ($FileDetails.PercentComplete -gt 0)
                                                                                        {
                                                                                            {($_ -eq $True)}
                                                                                              {
                                                                                                  $FileDetails.SecondsRemaining = ((($FileDetails.TotalSecondsElasped / $FileDetails.PercentComplete) * 100) - $FileDetails.TotalSecondsElasped) -As [Int]
                                                                                              }

                                                                                            Default
                                                                                              {
                                                                                                  $FileDetails.SecondsRemaining = (0) -As [Int]
                                                                                              }
                                                                                        }

                                                                                      $FileListDetails.PercentComplete = [System.Math]::Round((($FileListDetails.TransferredBytes / $FileListDetails.TotalBytes) * 100), 2)
                                                                                      
                                                                                      $FileListDetails.TotalSecondsElasped = $StopWatchTable.Primary.Elapsed.TotalSeconds -As [Int]

                                                                                      Switch ($FileListDetails.PercentComplete -gt 0)
                                                                                        {
                                                                                            {($_ -eq $True)}
                                                                                              {
                                                                                                  $FileListDetails.SecondsRemaining = ((($FileListDetails.TotalSecondsElasped / $FileListDetails.PercentComplete) * 100) - $FileListDetails.TotalSecondsElasped) -As [Int]
                                                                                              }

                                                                                            Default
                                                                                              {
                                                                                                  $FileListDetails.SecondsRemaining = ((($FileListDetails.TotalSecondsElasped / $FileListDetails.PercentComplete) * 100) - $FileListDetails.TotalSecondsElasped) -As [Int]
                                                                                              }
                                                                                        }

                                                                                      $TaskSequence = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                                        $TaskSequence.Environment = Try {New-Object -ComObject 'Microsoft.SMS.TSEnvironment'} Catch {$Null}
                                                                                        $TaskSequence.IsRunning = $Null -ine $TaskSequence.Environment

                                                                                      Switch ($TaskSequence.IsRunning)
                                                                                        {
                                                                                            {($_ -eq $True)}
                                                                                              {                                                                                                  
                                                                                                  $FileProgressParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                                                    $FileProgressParameters.ID = 1
                                                                                                    $FileProgressParameters.Activity = "$($FileDetails.PercentComplete)% - Downloading $($FileSystemObject.GetFile($FileObjectProperties.Destination.FullName).ShortName) @ $($FileDetails.TransferRate) Mbps ($($FileDetails.Number) of $($FileListDetails.Count))"
                                                                                                    $FileProgressParameters.Status = "$($FileDetails.PercentComplete)% - Downloading $($FileSystemObject.GetFile($FileObjectProperties.Destination.FullName).ShortName) @ $($FileDetails.TransferRate) Mbps ($($FileDetails.Number) of $($FileListDetails.Count))"
                                                                                                    $FileProgressParameters.PercentComplete = $FileDetails.PercentComplete
                                                                                                    $FileProgressParameters.SecondsRemaining = $FileDetails.SecondsRemaining
                
                                                                                                  Write-Progress @FileProgressParameters
                                                                                              }

                                                                                            Default
                                                                                              {
                                                                                                  $TotalProgressParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                                                    $TotalProgressParameters.ID = 1
                                                                                                    $TotalProgressParameters.Activity = "$($FileListDetails.PercentComplete)% - Copying file $($FileDetails.Number) of $($FileListDetails.Count) ($($FileListDetails.Count - $($FileListIndex)) left)"
                                                                                                    $TotalProgressParameters.Status = $FileObjectProperties.Source.FullName
                                                                                                    $TotalProgressParameters.PercentComplete = $FileListDetails.PercentComplete
                                                                                                    $TotalProgressParameters.SecondsRemaining = $FileListDetails.SecondsRemaining
                
                                                                                                  Write-Progress @TotalProgressParameters
                                                                                                  
                                                                                                  $FileProgressParameters = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                                                                                                    $FileProgressParameters.ParentID = $TotalProgressParameters.ID
                                                                                                    $FileProgressParameters.ID = $TotalProgressParameters.ID + 1
                                                                                                    $FileProgressParameters.Activity = "$($FileDetails.PercentComplete)% - Copying @ $($FileDetails.TransferRate) Mbps"
                                                                                                    $FileProgressParameters.Status = $FileObjectProperties.Destination.FullName
                                                                                                    $FileProgressParameters.PercentComplete = $FileDetails.PercentComplete
                                                                                                    $FileProgressParameters.SecondsRemaining = $FileDetails.SecondsRemaining
                
                                                                                                  Write-Progress @FileProgressParameters
                                                                                              }
                                                                                        }      
                                                                                  }
                                                                            }

                                                                          Switch ($RandomDelay.IsPresent)
                                                                            {
                                                                                {($_ -eq $True)}
                                                                                  {
                                                                                      $Delay = Get-Random -Minimum 1 -Maximum 1500
                                                                                    
                                                                                      $Null = Start-Sleep -Milliseconds ($Delay)
                                                                                  }
                                                                            }         
                                                                      }
                                                                    While ($FileDetails.SegmentBytes -gt 0)

                                                                    $Null = $FileDetails.Source.Close()

                                                                    $Null = $FileDetails.Destination.Close()

                                                                    $Null = $StopWatchTable.Secondary.Stop()

                                                                    $FileDetails = Get-Item -Path $FileObjectProperties.Destination.FullName -Force
                                                
                                                                    $FileAttributeList = $FileDetails.PSObject.Properties | Where-Object {($_.MemberType -iin @('NoteProperty', 'Property')) -and ($_.TypeNameOfValue -ieq 'System.DateTime') -and ($_.IsSettable -eq $True) -and ($_.Name -inotmatch '.*UTC.*')}
                                                    
                                                                    ForEach ($FileAttribute In $FileAttributeList)
                                                                      {
                                                                          #$LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Attempting to update file attribute `"$($FileAttribute.Name)`" on file `"$($FileDetails.FullName)`" from `"$($FileDetails.$($FileAttribute.Name))`" to `"$($FileObjectProperties.Source.$($FileAttribute.Name))`". Please Wait..." 
                                                                          #Write-Verbose -Message ($LoggingDetails.LogMessage)
                                                          
                                                                          $FileDetails.$($FileAttribute.Name) = $FileObjectProperties.Source.$($FileAttribute.Name)
                                                                      }

                                                                    $FileObjectProperties.Destination = $FileDetails

                                                                    $FileObjectProperties.Status = 'Successful'
                                                                }
                        
                                                              Default
                                                                {
                                                                    $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - File `"$($FileObjectProperties.Destination.FullName)`" already exists. Skipping." 
                                                                    Write-Verbose -Message ($LoggingDetails.WarningMessage)

                                                                    $FileObjectProperties.Status = 'Skipped'
                                                                }
                                                          }            
                                                    }
                                                  Catch
                                                    {                                                      
                                                        $FileObjectProperties.Status = 'Error'
                                                      
                                                        $ErrorHandlingDefinition.Invoke()
                                                    }
                                                  Finally
                                                    {
                                                        $FileObjectProperties.TimeToTransfer = $StopWatchTable.Secondary.Elapsed
                                                                      
                                                        $Null = $StopWatchTable.Secondary.Reset()
                                                      
                                                        $FileObject = New-Object -TypeName 'PSObject' -Property ($FileObjectProperties)
                      
                                                        $OutputObjectList.Add($FileObject)
                                                    }
                                              }

                                            $Null = $StopWatchTable.Primary.Stop()

                                            $Null = $StopWatchTable.Primary.Reset()

                                            $FileListStatusGroups = $OutputObjectList | Group-Object -Property 'Status' | Sort-Object -Property @('Name')

                                            ForEach ($FileListStatusGroup In $FileListStatusGroups)
                                              {
                                                  $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - $($FileListStatusGroup.Count) of $($FileListDetails.Count) file(s) have a status of `"$($FileListStatusGroup.Name)`"." 
                                                  Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose
                                              }
                                        }
            
                                      Default
                                        {
                                            $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - There are $($FileListDetails.Count) file(s) to copy to `"$($Destination.FullName)`". No further action will be taken." 
                                            Write-Verbose -Message ($LoggingDetails.WarningMessage) -Verbose
                                        }
                                  }
                            }

                          Default
                            {
                                $LoggingDetails.WarningMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - There were 0 paths specified to search. No further action will be taken." 
                                Write-Warning -Message ($LoggingDetails.WarningMessage)
                            }
                      }                
                }
              Catch
                {
                    $ErrorHandlingDefinition.Invoke()
                }
              Finally
                {
                    $Null = Start-Sleep -Seconds 3
                }
          }
        
        End
          {                                        
              Try
                {
                    #Determine the date and time the function completed execution
                      $FunctionEndTime = (Get-Date)

                      $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Execution of $($FunctionName) ended on $($FunctionEndTime.ToString($DateTimeLogFormat))"
                      Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose

                    #Log the total script execution time  
                      $FunctionExecutionTimespan = New-TimeSpan -Start ($FunctionStartTime) -End ($FunctionEndTime)

                      $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Function execution took $($FunctionExecutionTimespan.Hours.ToString()) hour(s), $($FunctionExecutionTimespan.Minutes.ToString()) minute(s), $($FunctionExecutionTimespan.Seconds.ToString()) second(s), and $($FunctionExecutionTimespan.Milliseconds.ToString()) millisecond(s)"
                      Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose
                    
                    $LoggingDetails.LogMessage = "$($GetCurrentDateTimeMessageFormat.Invoke()) - Function `'$($FunctionName)`' is completed."
                    Write-Verbose -Message ($LoggingDetails.LogMessage) -Verbose
                }
              Catch
                {
                    $ErrorHandlingDefinition.Invoke()
                }
              Finally
                {
                    #Write the object to the powershell pipeline
                      $OutputObjectList = $OutputObjectList.ToArray()

                      Write-Output -InputObject ($OutputObjectList)
                }
          }
    }
#endregion