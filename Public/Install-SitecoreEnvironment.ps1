function Install-SitecoreEnvironment {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	Import-Module WebAdministration

	$parameters = Get-Content $Path -Raw | ConvertFrom-Json

	foreach ($server in $parameters.servers) {
		$xConnectHostName = "$($parameters.installation.prefix).xconnect"
		$sitecoreHostName = "$($parameters.installation.prefix).local"

		$xConnectClientCertificateName = "$($parameters.installation.prefix).xconnect_client"

		if ($server.selfSignedCert) {
			#install client certificate for xConnect 
			$certParams = 
			@{     
				Path            = $parameters.assets.certificates.createCertJson
				CertificateName = $xConnectClientCertificateName
			} 
			Install-SitecoreConfiguration @certParams -Verbose:$VerbosePreference
		}

		#install Solr cores for xDB 
		$solrParams = 
		@{
			Path        = $parameters.assets.xConnect.solrJson  
			SolrUrl     = $parameters.solr.url
			SolrRoot    = $parameters.solr.root
			SolrService = $parameters.solr.service
			CorePrefix  = $parameters.installation.prefix
		} 
		Install-SitecoreConfiguration @solrParams -Verbose:$VerbosePreference

		#deploy xConnect instance 
		$xconnectParams = 
		@{
			Path             = $parameters.assets.xConnect.installJson
			Package          = $parameters.assets.xConnect.installPackage
			LicenseFile      = $parameters.assets.xConnect.license
			SiteName         = $xConnectHostName
			XConnectCert     = $xConnectClientCertificateName
			SqlDbPrefix      = $parameters.installation.prefix
			SqlServer        = $parameters.sql.hostName
			SqlAdminUser     = $parameters.sql.username
			SqlAdminPassword = $parameters.sql.password
			SolrCorePrefix   = $parameters.installation.prefix
			SolrUrl          = $parameters.solr.url
		} 
		Install-SitecoreConfiguration @xconnectParams -Verbose:$VerbosePreference

		#install Solr cores for Sitecore 
		$solrParams = 
		@{
			Path        = $parameters.assets.sitecore.solrJson
			SolrUrl     = $parameters.solr.url
			SolrRoot    = $parameters.solr.root
			SolrService = $parameters.solr.service
			CorePrefix  = $parameters.installation.prefix
		} 
		Install-SitecoreConfiguration @solrParams -Verbose:$VerbosePreference
 
		#install Sitecore instance 
		$sitecoreParams = 
		@{     
			Path                      = $parameters.assets.sitecore.installJson
			Package                   = $parameters.assets.sitecore.installPackage
			LicenseFile               = $parameters.assets.sitecore.license
			SqlDbPrefix               = $parameters.installation.prefix
			SqlServer                 = $parameters.sql.hostName
			SqlAdminUser              = $parameters.sql.username
			SqlAdminPassword          = $parameters.sql.password
			SolrCorePrefix            = $parameters.installation.prefix
			SolrUrl                   = $parameters.solr.url
			XConnectCert              = $xConnectClientCertificateName
			SiteName                  = $sitecoreHostName
			XConnectCollectionService = "https://$xConnectHostName"
		} 
		Install-SitecoreConfiguration @sitecoreParams -Verbose:$VerbosePreference
	}
}