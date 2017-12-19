function Install-SitecoreInstallationModules {
	[cmdletbinding()]
	param(
		[string]$RepositoryName = "SitecoreGallery"
	)

	$repository = Get-PSRepository -Name $RepositoryName -ErrorAction Ignore

	if ($repository -eq $null)
	{
		Write-Host "Sitecore PS repository not specified or not installed. Installing repository as '$RepositoryName'."

		# TODO: Check for package provider
		Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force

		Register-PSRepository -Name $RepositoryName -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2"
		Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted

		Write-Host "Repository '$RepositoryName' registered."
	}

	if (-not (Get-Module -ListAvailable -Name "SitecoreInstallFramework"))
	{
		Write-Host "Sitecore Install Framework module not installed. Installing module..."
		Install-Module SitecoreInstallFramework
		Write-Host "Sitecore Install Framework module successfully installed."
	}
	else {
		Write-Host "Sitecore Install Framework module already installed. Checking for updates..."
		Update-Module SitecoreInstallFramework
		Write-Host "Sitecore Install Framework module successfully updated."
	}
}

Export-ModuleMember -Function Install-SitecoreInstallationModules