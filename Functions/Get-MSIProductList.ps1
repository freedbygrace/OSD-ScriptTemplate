Function Get-MSIProductList
  {
      $OutputObjectList = New-Object -TypeName 'System.Collections.Generic.List[PSObject]'
      
      $ComObject = New-Object -ComObject 'WindowsInstaller.Installer'

      $ComObjectType = $ComObject.GetType()

      [String[]]$AttributeList = @('Language', 'ProductName', 'PackageCode', 'Transforms', 'AssignmentType', 'PackageName', 'InstalledProductName', 'VersionString', 'RegCompany', 'RegOwner', 'ProductID', 'ProductIcon', 'InstallLocation', 'InstallSource', 'InstallDate', 'Publisher', 'LocalPackage', 'HelpLink', 'HelpTelephone', 'URLInfoAbout', 'URLUpdateInfo') | Sort-Object

      $ProductList = $ComObjectType.InvokeMember('Products', [System.Reflection.BindingFlags]::GetProperty, $Null, $ComObject, $Null)
      
      ForEach ($Product In $ProductList)
        {
            $OutputObjectProperties = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
              $OutputObjectProperties.Add('ProductCode', $Product)

            For ($AttributeListIndex = 0; $AttributeListIndex -lt $AttributeList.Count; $AttributeListIndex++)
              {
                  [String]$AttributeName = $AttributeList[$AttributeListIndex]

                  Switch ($OutputObjectProperties.Contains($AttributeName))
                    {
                        {($_ -eq $False)}
                          {
                              $OutputObjectProperties.Add($AttributeName, $Null)
                          }    
                    }

                  Try {$OutputObjectProperties."$($AttributeName)" = $ComObjectType.InvokeMember('ProductInfo', [System.Reflection.BindingFlags]::GetProperty, $Null, $ComObject, @($Product, $AttributeName))} Catch {}         
              }

            $OutputObject = New-Object -TypeName 'PSObject' -Property ($OutputObjectProperties)

            $Null = $OutputObjectList.Add($OutputObject)
        }

      Write-Output -InputObject ($OutputObjectList)
  }

#Get-MSIProductList