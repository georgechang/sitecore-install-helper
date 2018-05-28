function Install-SitecoreInstallationModule {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[string]$RepositoryName = "SitecoreGallery"
	)

	$repository = Get-PSRepository -Name $RepositoryName -ErrorAction Ignore

	if ($null -eq $repository) {
		Write-Verbose "Sitecore PS repository not specified or not installed. Installing repository as '$RepositoryName'."

		# catch exception thrown by Get-PackageProvider
		if (-not (Get-PackageProvider -ListAvailable -Name "NuGet")) {
			Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force
		}

		Register-PSRepository -Name $RepositoryName -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2"
		Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted

		Write-Verbose "Repository '$RepositoryName' registered."
	}

	if (-not (Get-Module -ListAvailable -Name "SitecoreInstallFramework")) {
		Write-Verbose "Sitecore Install Framework module not installed. Installing module..."
		Install-Module SitecoreInstallFramework
		Write-Verbose "Sitecore Install Framework module successfully installed."
	}
	else {
		Write-Verbose "Sitecore Install Framework module already installed. Checking for updates..."
		Update-Module SitecoreInstallFramework
		Write-Verbose "Sitecore Install Framework module successfully updated."
	}
}