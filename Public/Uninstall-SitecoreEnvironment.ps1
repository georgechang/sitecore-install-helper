function Uninstall-SitecoreEnvironment {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Prefix
	)

	Remove-XConnectServices -Prefix $Prefix

	Remove-IISWebsiteAppPool -Name $Prefix.local
	Remove-IISWebsiteAppPool -Name $Prefix.xconnect

	Remove-SqlServerDatabases -Prefix $Prefix
}