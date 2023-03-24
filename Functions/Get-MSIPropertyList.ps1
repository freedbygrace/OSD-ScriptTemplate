Function Get-MSIPropertyList
  {
      [CmdletBinding()]
        Param
          (
              [Parameter(Mandatory=$True)]
              [ValidateNotNullOrEmpty()]
              [ValidateScript({(Test-Path -Path $_)})]
              [System.IO.FileInfo[]]$Path
          )

      Begin
        {
            $OutputObjectList = New-Object -TypeName 'System.Collections.Generic.List[PSObject]'
        }

      Process
        {
            Try
              {
                  ForEach ($Item In $Path)
                    {
                        $ComObject = New-Object -ComObject 'WindowsInstaller.Installer'
                        
                        $MSIDatabase = $ComObject.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $Null, $ComObject, @($Item.FullName, 0))
                  
                        [String]$Query = 'SELECT * FROM Property'
                  
                        $View = $MSIDatabase.GetType().InvokeMember('OpenView', 'InvokeMethod', $Null, $MSIDatabase, $Query) 
                          $View.GetType().InvokeMember('Execute', 'InvokeMethod', $Null, $View, $Null)
      
                        $OutputObjectProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                          $OutputObjectProperties.Add('Path', $Item)
      
                        While ($Record = $View.GetType().InvokeMember('Fetch', 'InvokeMethod', $Null, $View, $Null))
                          {
                              Switch ($Null -ine $Record)
                                {
                                    {($_ -eq $True)}
                                      {
                                          [String]$MSIPropertyName = $Record.GetType().InvokeMember('StringData', 'GetProperty', $Null, $Record, 1)
                                          [String]$MSIPropertyValue = $Record.GetType().InvokeMember('StringData', 'GetProperty', $Null, $Record, 2)
                  
                                          Switch ($OutputObjectProperties.Contains($MSIPropertyName))
                                            {
                                                {($_ -eq $False)}
                                                  {
                                                      $OutputObjectProperties.Add($MSIPropertyName, $MSIPropertyValue)
                                                  }
                                            }
                                      }
                                }
                          }
                  
                        $OutputObject = New-Object -TypeName 'PSObject' -Property ($OutputObjectProperties)
      
                        $OutputObjectList.Add($OutputObject)
                        
                        $Null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($MSIDatabase)
      
                        $Null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ComObject)
                    }
              }
            Catch
              {
                  $ErrorMessageList = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
                    $ErrorMessageList.Add('ErrorMessage', $_.Exception.Message)
                    $ErrorMessageList.Add('Command', $_.InvocationInfo.MyCommand.Name)
                    $ErrorMessageList.Add('LineNumber', $_.InvocationInfo.ScriptLineNumber)
                    $ErrorMessageList.Add('LinePosition', $_.InvocationInfo.OffsetInLine)
                    $ErrorMessageList.Add('Code', $_.InvocationInfo.Line.Trim())
              
                  ForEach ($ErrorMessage In $ErrorMessageList.GetEnumerator())
                    {
                        $ErrorMessage = "$($ErrorMessage.Key): $($ErrorMessage.Value)"
                        Write-Warning -Message ($ErrorMessage) -Verbose
                    }
              }
            Finally
              {     
                  $OutputObjectList = $OutputObjectList.ToArray()
                  
                  Write-Output -InputObject ($OutputObjectList)            
              }
        }

      End
        {

        }
  }