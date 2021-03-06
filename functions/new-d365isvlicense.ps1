﻿<#
.SYNOPSIS
Create a license deployable package 

.DESCRIPTION
Create a deployable package with a license file inside

.PARAMETER LicenseFile
Path to the license file that you want to have inside a deployable package

.PARAMETER Path
Path to the template zip file for creating a deployable package with a license file

Default path is the same as the aos service "PackagesLocalDirectory\bin\CustomDeployablePackage\ImportISVLicense.zip"

.PARAMETER OutputPath
Path where you want the generated deployable package stored

Default value is: "C:\temp\d365fo.tools\ISVLicense.zip"

.EXAMPLE
New-D365ISVLicense -LicenseFile "C:\temp\ISVLicenseFile.txt"

This will take the "C:\temp\ISVLicenseFile.txt" file and locate the "ImportISVLicense.zip" template file under the "PackagesLocalDirectory\bin\CustomDeployablePackage\".
It will extract the "ImportISVLicense.zip", load the ISVLicenseFile.txt and compress (zip) the files into a deployable package.
The package will be exported to "C:\temp\d365fo.tools\ISVLicense.zip"

.NOTES
Author: Mötz Jensen (@splaxi)

#>
function New-D365ISVLicense {
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory = $true, Position = 1)]        
        [string] $LicenseFile,

        [Alias('Template')]
        [string] $Path = "$Script:BinDirTools\CustomDeployablePackage\ImportISVLicense.zip",

        [string] $OutputPath = "C:\temp\d365fo.tools\ISVLicense.zip"

    )

    begin {
        $oldprogressPreference = $global:progressPreference
        $global:progressPreference = 'silentlyContinue'
    }
    
    process {

        if (-not (Test-PathExists -Path $Path, $LicenseFile -Type "Leaf")) {return}

        $null = New-Item -Path (Split-Path $OutputPath -Parent) -ItemType Directory -ErrorAction SilentlyContinue

        Unblock-File $Path
        Unblock-File $LicenseFile

        $ExtractionPath = [System.IO.Path]::GetTempPath()

        $packageTemp = Join-Path $ExtractionPath ((Get-Random -Maximum 99999).ToString())

        Write-PSFMessage -Level Verbose -Message "Extracting the template zip file to $packageTemp." -Target $packageTemp
        Expand-Archive -Path $Path -DestinationPath $packageTemp

        $licenseMergePath = Join-Path $packageTemp "AosService\Scripts\License"

        Get-ChildItem -Path $licenseMergePath | Remove-Item -Force -ErrorAction SilentlyContinue

        Write-PSFMessage -Level Verbose -Message "Copying the license file into place."
        Copy-Item -Path $LicenseFile -Destination $licenseMergePath

        Write-PSFMessage -Level Verbose -Message "Compressing the folder into a zip file and storing it at $OutputPath" -Target $OutputPath
        Compress-Archive -Path "$packageTemp\*" -DestinationPath $OutputPath -Force

        [PSCustomObject]@{
            File = $OutputPath
        }
    }

    end {
        $global:progressPreference = $oldprogressPreference
    }
}