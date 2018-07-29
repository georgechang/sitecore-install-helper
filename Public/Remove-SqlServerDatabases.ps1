function Remove-SqlServerDatabases {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Prefix,
		[string]$Username,
		[securestring]$Password
	)
	
	Import-Module SqlServer

	#$credential = New-SqlCredential -Name "sqlcredential" -Identity $Username -Secret $Password
	
	Get-SqlInstance -Path "SQLSERVER:\SQL\$env:computername\DEFAULT" | Get-SqlDatabase | ? { $_.Name.StartsWith("$Prefix_") } | % { $_.Drop() }
}