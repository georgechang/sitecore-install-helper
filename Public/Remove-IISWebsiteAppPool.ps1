function Remove-IISWebsiteAppPool {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Name
	)
	
	Import-Module WebAdministration

	$site = Get-Website -Name $Name

	if ($site) {
		Write-Verbose "IIS Site ($Name) found."
		Write-Verbose "Stopping IIS Site ($Name)..."
		Stop-Website -Name $Name

		Write-Verbose "Removing IIS Site ($Name)..."
		Remove-Website -Name $Name

		if (Test-Path $site.physicalPath) {
			Remove-Item $site.physicalPath -Recurse
		}
	}

	if (Test-Path "IIS:\AppPools\$Name") {
		Write-Verbose "Removing Application Pool ($Name)..."
		Remove-WebAppPool -Name $Name
	}
}