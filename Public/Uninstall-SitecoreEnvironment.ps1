function Uninstall-SitecoreEnvironment {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Prefix
	)

	$marketingAutomationServiceName = "$Prefix.xconnect-MarketingAutomationService"
	$indexWorkerName = "$Prefix.xconnect-IndexWorker"
	$processingEngineServiceName = "$Prefix.xconnect-ProcessingEngineService"

	Remove-WindowsService -Name $marketingAutomationServiceName
	Remove-WindowsService -Name $indexWorkerName
	Remove-WindowsService -Name $processingEngineServiceName

	Remove-IISWebsiteAppPool -Name "$Prefix.sitecore"
	Remove-IISWebsiteAppPool -Name "$Prefix.xconnect"
	Remove-IISWebsiteAppPool -Name "$Prefix.identityserver"

	Remove-SqlServerDatabases -Prefix $Prefix
}