<#
.SYNOPSIS
Returns information about D365FO

.DESCRIPTION
Gets detailed information about application and platform

.EXAMPLE
Get-ProductInfoProvider

This will get product, platform and application version details for the environment

.NOTES
The cmdlet wraps the call against a dll file that is shipped with Dynamics 365 for Finance & Operations. 
The call to the dll file gets all relevant product details for the environment.

#>
function Get-D365ProductInformation {
    [CmdletBinding()]
    param ()
    
    return Get-ProductInfoProvider
}