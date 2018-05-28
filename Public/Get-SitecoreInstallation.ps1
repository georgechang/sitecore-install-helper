function Get-SitecoreInstallation {
	[CmdletBinding()]
	param(
		[string]$Path,
		[string]$Url,
		[string]$UserName,
		[SecureString]$Password		
	)
	$credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $UserName, $Password
	$networkCredential = $credential.GetNetworkCredential()

	Write-Verbose "Logging into Sitecore..."
	Invoke-RestMethod -Uri https://dev.sitecore.net/api/authorization -Method Post -ContentType "application/json" -Body "{username: '$($networkCredential.UserName)', password: '$($networkCredential.Password)'}" -SessionVariable session -UseBasicParsing
	Write-Verbose "Authenticated with Sitecore."
	Write-Verbose "Downloading Sitecore package..."
	Invoke-WebRequest -Uri $url -WebSession $session -OutFile $Path -UseBasicParsing
	Write-Verbose "Sitecore package downloaded."
}

