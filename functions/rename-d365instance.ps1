<#
.SYNOPSIS
Rename as D365FO Demo/Dev box

.DESCRIPTION
The Rename function, changes the config values used by a D365FO dev box for identifying its name. Standard it is called 'usnconeboxax1aos'

.PARAMETER NewName
The new name wanted for the D365FO instance

.PARAMETER AosServiceWebRootPath
Path to the webroot folder for the AOS service 'Default value : C:\AOSService\Webroot

.PARAMETER IISServerApplicationHostConfigFile
Path to the IISService Application host file, [Where the binding configurations is stored] 'Default value : C:\Windows\System32\inetsrv\Config\applicationHost.config'

.PARAMETER HostsFile
Place of the host file on the current system [Local DNS record] ' Default value C:\Windows\System32\drivers\etc\hosts'

.PARAMETER BackupExtension
Backup name for all the files that are changed

.PARAMETER MRConfigFile
Parameter description

.PARAMETER RenameMachine
Switch to instruct the cmdlet to rename the windows machine as well

.EXAMPLE
Rename-D365Instance -NewName 'Demo1'

.NOTES
The function restarts the IIS Service.

Elevated privileges are required
#>

function Rename-D365Instance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$NewName,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$AosServiceWebRootPath = $Script:AOSPath,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]$IISServerApplicationHostConfigFile = $Script:IISHostFile,

        [Parameter(Mandatory = $false, Position = 4)]
        [string]$HostsFile = $Script:Hosts,

        [Parameter(Mandatory = $false, Position = 5)]
        [string]$BackupExtension = "bak",

        [Parameter(Mandatory = $false, Position = 6)]
        [string]$MRConfigFile = $Script:MRConfigFile

    )

    Write-PSFMessage -Level Verbose -Message "Testing for elevated runtime"

    if ($Script:EnvironmentType -ne [EnvironmentType]::LocalHostedTier1) {
        Write-PSFMessage -Level Host -Message "It seems that you ran this cmdlet on a machine that is not a local hosted tier 1 / one box. This cmdlet is only supporting on a <c='em'>onebox / local tier 1</c> machine."
        Stop-PSFFunction -Message "Stopping because machine isn't a onebox"
        return
    }
    elseif (!$script:IsAdminRuntime) {
        Write-PSFMessage -Level Host -Message "The cmdlet needs <c='em'>administrator permission</c> (Run As Administrator) to be able to update the configuration. Please start an <c='em'>elevated</c> session and run the cmdlet again."
        Stop-PSFFunction -Message "Stopping because the function is not run elevated"
        return
    }

    $OldName = (Get-D365InstanceName).Instancename

    Write-PSFMessage -Level Verbose -Message "Old name collected and will be used to rename." -Target $OldName

    # Variables
    $replaceValue = $OldName
    $NewNameDot = "$NewName."
    $replaceValueDot = "$replaceValue."

    $WebConfigFile = join-Path -path $AosServiceWebRootPath $Script:WebConfig
    $WifServicesFile = Join-Path -Path $AosServiceWebRootPath $Script:WifServicesConfig

    $Files = @($WebConfigFile, $WifServicesFile, $IISServerApplicationHostConfigFile, $HostsFile, $MRConfigFile)
    foreach ($item in $Files) {
        Write-PSFMessage -Level Verbose -Message "Testing file path." -Target $item

        if ((Test-Path $item -PathType Leaf) -eq $false) {
            Write-PSFMessage -Level Host -Message "The <c='em'>$item</c> file wasn't found. Please ensure the file <c='em'>exists </c> and you have enough <c='em'>permission/c> to access the file."
            Stop-PSFFunction -Message "Stopping because a file is missing."
            return
        }    
    }

    Write-PSFMessage -Level Verbose -Message "Stopping the IIS."
    iisreset /stop

    # Backup files
    if ($null -ne $BackupExtension -and $BackupExtension -ne '') {
        foreach ($item in $Files) {   
            Backup-File $item $BackupExtension
        }
    }

    # WebConfig - D365 web config file
    Rename-ConfigValue $WebConfigFile $NewName $replaceValue
    # Wif.Services - D365 web config file (services)
    Rename-ConfigValue $WifServicesFile $NewName $replaceValue
    #ApplicationHost - IIS Bindings
    Rename-ConfigValue $IISServerApplicationHostConfigFile $NewNameDot $replaceValueDot
    #Hosts file - local DNS cache
    Rename-ConfigValue $HostsFile $NewNameDot $replaceValueDot
    #Management Reporter
    Rename-ConfigValue $MRConfigFile $NewName $replaceValue

    #Start IIS again
    Write-PSFMessage -Level Verbose -Message "Starting the IIS."
    iisreset /start

    Get-D365Url -Force
}


