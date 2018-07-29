function Remove-IISWebsiteAppPool {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Name
	)
	
	Import-Module WebAdministration

	$site = Get-Website -Name $Name

	if ($site) {
		$site | Stop-Website
		if (Test-Path $site.physicalPath) {
			Remove-Item $site.physicalPath
		}
		$site | Remove-Website
	}

	if (Test-Path "IIS:\AppPools\$Name") {
		Remove-WebAppPool -Name $Name
	}
}