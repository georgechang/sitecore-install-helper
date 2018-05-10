function Install-SitecoreEnvironment {
	param(
		[switch]$SelfSignedCertificate,
		[string]$XConnectClientCertificateName,
		[string]$XConnectInstallationPath,
		[string]$SitecoreInstallationPath,
		[string]$LicenseXmlFilePath,
		[string]$SolrServiceUrl,
		[string]$SolrInstallPath,
		[string]$SolrServiceName,
		[string]$SqlServerHostName,
		[string]$SqlAdminUserName,
		[securestring]$SqlAdminPassword,
		[string]$Prefix,
		[string]$SqlServerDatabasePrefix,
		[string]$SolrCorePrefix,
		[string]$SitecoreHostName,
		[string]$XConnectHostName
	)
	{
		#define parameters 
		$PSScriptRoot = "C:\Sitecore\Install\Sitecore 9.0.0 rev. 171002"
		if (!$SitecoreHostName) {
			$SitecoreHostName = "$Prefix.local"
		}
		if (!$XConnectHostName) {
			$XConnectHostName = "$Prefix.xconnect"
		}
		if (!$SqlServerDatabasePrefix) {
			$SqlServerDatabasePrefix = $Prefix
		}
		if (!$SolrCorePrefix) {
			$SolrCorePrefix = $Prefix
		}
 
		if ($SelfSignedCertificate) {
			if (!$XConnectClientCertificateName) {
				$XConnectClientCertificateName = "$Prefix.xconnect_client"
			}

			#install client certificate for xConnect 
			$certParams = 
			@{     
				Path            = "$PSScriptRoot\xconnect-createcert.json"
				CertificateName = $XConnectClientCertificateName
			} 
			Install-SitecoreConfiguration @certParams -Verbose
		}

		#install Solr cores for xDB 
		$solrParams = 
		@{
			Path        = "$PSScriptRoot\xconnect-solr.json"     
			SolrUrl     = $SolrUrl    
			SolrRoot    = $SolrRoot  
			SolrService = $SolrService  
			CorePrefix  = $SolrCorePrefix 
		} 
		Install-SitecoreConfiguration @solrParams -Verbose

		#deploy xConnect instance 
		$xconnectParams = 
		@{
			Path             = "$PSScriptRoot\xconnect-xp0.json"
			Package          = $XConnectInstallationPath
			LicenseFile      = $LicenseXmlFilePath
			SiteName         = $XConnectHostName
			XConnectCert     = $XConnectClientCertificateName
			SqlDbPrefix      = $SqlServerDatabasePrefix
			SqlServer        = $SqlServerHostName
			SqlAdminUser     = $SqlAdminUser
			SqlAdminPassword = $SqlAdminPassword
			SolrCorePrefix   = $SolrCorePrefix
			SolrUrl          = $SolrServiceUrl
		} 
		Install-SitecoreConfiguration @xconnectParams -Verbose

		#install Solr cores for Sitecore 
		$solrParams = 
		@{
			Path        = "$PSScriptRoot\sitecore-solr.json"
			SolrUrl     = $SolrServiceUrl
			SolrRoot    = $SolrInstallPath
			SolrService = $SolrServiceName
			CorePrefix  = $SolrCorePrefix 
		} 
		Install-SitecoreConfiguration @solrParams -Verbose
 
		#install Sitecore instance 
		$sitecoreParams = 
		@{     
			Path                      = "$PSScriptRoot\sitecore-XP0.json"
			Package                   = $SitecoreInstallationPath
			LicenseFile               = $LicenseXmlFilePath
			SqlDbPrefix               = $SqlServerDatabasePrefix
			SqlServer                 = $SqlServerHostName
			SqlAdminUser              = $SqlAdminUserName
			SqlAdminPassword          = $SqlAdminPassword
			SolrCorePrefix            = $SolrCorePrefix
			SolrUrl                   = $SolrServiceUrl
			XConnectCert              = $XConnectClientCertificateName
			SiteName                  = $SitecoreHostName
			XConnectCollectionService = "https://$XConnectHostName"
		} 
		Install-SitecoreConfiguration @sitecoreParams -Verbose

		$sitecoreParams = 
		@{     
			Path                                 = "$PSScriptRoot\sitecore-XP1-cd.json"
			Package                              = "$PSScriptRoot\Sitecore 9.0.0 rev. 171002 (OnPrem)_cd.scwdp.zip"
			LicenseFile                          = "$PSScriptRoot\license.xml"
			SqlDbPrefix                          = "sask"
			SolrCorePrefix                       = "sask"
			XConnectCert                         = "www-dc9-cd-q1"
			SiteName                             = "sask"
			SqlCoreUser                          = "coreuser"
			SqlCorePassword                      = "Test12345"
			SqlWebUser                           = "webuser"
			SqlWebPassword                       = "Test12345"
			SqlFormsUser                         = "formsuser"
			SqlFormsPassword                     = "Test12345"
			SqlServer                            = "saskpower-qadev-sqlelastic.database.windows.net"
			SolrUrl                              = "https://www-dc9-cm-q1:8983/solr"
			XConnectCollectionService            = "https://www-dc9-cm-q1:4433"
			XConnectReferenceDataService         = "https://www-dc9-cm-q1:4433"
			MarketingAutomationOperationsService = "https://www-dc9-cm-q1:4433"
			MarketingAutomationReportingService  = "https://www-dc9-cm-q1:4433"
		} 
		Install-SitecoreConfiguration @sitecoreParams -Verbose
	}
}