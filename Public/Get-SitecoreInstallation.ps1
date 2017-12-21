function Get-SitecoreInstallation {
	param(
		[string]$Path,
		[string]$Url,
		[string]$UserName,
		[string]$Password		
	)
	$loginRequest = Invoke-RestMethod -Uri https://dev.sitecore.net/api/authorization -Method Post -ContentType "application/json" -Body "{username: '$UserName', password: '$Password'}" -SessionVariable session -UseBasicParsing
	Invoke-WebRequest -Uri $url -WebSession $session -OutFile $Path -UseBasicParsing
}

# Install-SitecoreConfiguration -Path ./xconnect-solr.json -SolrUrl https://localhost:8983/solr -SolrRoot C:\solr-6.6.2 -SolrService solr662 -CorePrefix sask

# Install-SitecoreConfiguration -Path ./xconnect-xp0.json -Package './Sitecore 9.0.0 rev. 171002 (Hybrid)_xp0xconnect.scwdp.zip' -LicenseFile ./license.xml -XConnectCert www-dc9-cm-q1 -SqlDbPrefix "sask" -SqlServer saskpower-qadev-sqlelastic.database.windows.net -SqlAdminUser serveradmin -SqlAdminPassword saskSC9azure -SolrCorePrefix "sask" -SolrUrl "https://localhost:8983/solr"

# Install-SitecoreConfiguration -Path ./sitecore-solr.json -SolrUrl https://localhost:8983/solr -SolrRoot C:\solr-6.6.2 -SolrService solr662 -CorePrefix 'sask'

# Install-SitecoreConfiguration -Path ./sitecore-XP0.json -Package '.\Sitecore 9.0.0 rev. 171002 (Hybrid)_single.scwdp.zip' -LicenseFile .\license.xml -SolrCorePrefix 'sask' -SolrUrl https://localhost:8983/solr -XConnectCert www-dc9-cm-q1 -SiteName 'sask' -XConnectCollectionService https://xconnect -SqlDbPrefix 'sask' -SqlServer saskpower-qadev-sqlelastic.database.windows.net -SqlAdminUser 'serveradmin' -SqlAdminPassword 'saskSC9azure'

# New-WebBinding -Name sask -Protocol https -Port 443 -HostHeader sask
#associate cert with web binding

