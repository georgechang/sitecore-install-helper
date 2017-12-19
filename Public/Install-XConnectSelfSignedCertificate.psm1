function Install-XConnectSelfSignedCertificate {
	[cmdletbinding()]
	param(
		[string]$CertificateName
	)
	
	$certParams = 
	@{     
		Path = "$PSScriptRoot\..\Private\json\xconnect-createcert.json"
		CertificateName = $CertificateName 
	} 
	Install-SitecoreConfiguration @certParams -Verbose:$VerbosePreference
}

Export-ModuleMember -Function Install-XConnectSelfSignedCertificate