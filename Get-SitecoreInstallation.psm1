function Get-SitecoreInstallation {
	param(
		[string]$Url,
		[string]$UserName,
		[string]$Password,
		[string]$FilePath
	)
	$loginRequest = Invoke-RestMethod -Uri https://dev.sitecore.net/api/authorization -Method Post -ContentType "application/json" -Body "{username: '$UserName', password: '$Password'}" -SessionVariable session -UseBasicParsing
	Invoke-WebRequest -Uri $url -WebSession $session -OutFile $FilePath -UseBasicParsing
}

function Get-SolrInstallation {
	param(
		[string]$Version,
		[string]$FilePath
	)
	Invoke-WebRequest -Uri "http://mirrors.gigenet.com/apache/lucene/solr/$Version/solr-$Version.zip" -OutFile  $FilePath -UseBasicParsing
}

function Get-JreInstallation {
	param(
		[string]$Url,
		[string]$FilePath
	)
	$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
	$cookie = New-Object System.Net.Cookie
	$cookie.Name = "oraclelicense"
	$cookie.Value = "accept-securebackup-cookie"
	$cookie.Domain = ".oracle.com"
	$session.Cookies.Add($cookie)
	Invoke-WebRequest -Uri $Url -WebSession $session -OutFile $FilePath -UseBasicParsing
}

$env:Path += ';C:\Program Files\Java\jre-9.0.1\bin'

./nssm.exe install solr662 "C:\solr-6.6.2\bin\solr.cmd" start -f -p 8983
./nssm.exe set solr662 DisplayName "Solr 6.6.2"
./nssm.exe set solr662 Description "Service for Solr 6.6.2"
[Environment]::SetEnvironmentVariable("PATH", "C:\Program Files\Java\jre-9.0.1", [System.EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jre-9.0.1", [System.EnvironmentVariableTarget]::Machine)

& "C:\Program Files\Java\jre-9.0.1\bin\keytool.exe" -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass secret -storepass secret -validity 365 -keystore solr-ssl.keystore.jks -ext SAN=DNS:localhost,IP:127.0.0.1 -dname "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country"
& "C:\Program Files\Java\jre-9.0.1\bin\keytool.exe" -importkeystore -srcalias solr-ssl -destalias solr-ssl -srckeystore solr-ssl.keystore.jks -destkeystore solr-ssl.keystore.p12 -srcstoretype jks -deststoretype pkcs12 -srcstorepass $SrcKeystoreSecret -deststorepass $DestKeystoreSecret -srckeypass $SrcKeystoreSecret -destkeypass $DestKeystoreSecret -noprompt
Copy-Item solr-ssl.keystore.jks C:\solr\solr-6.6.2\server\etc

$solrincmdContent = Get-Content $solrincmdPath

foreach($content in $solrincmdContent)
{
	if ($content -match "^REM set SOLR_SSL_(?!CLIENT)")
	{
		Write-Verbose "Old content: $content"
		$content = $content.replace("REM ", "")
		if ($content -match " SOLR_SSL_(KEY|TRUST)_STORE=")
		{
			$content = $content.Substring(0, $content.IndexOf('=')) + "=$solrServerKeystorePath"
		}
		elseif ($content -match " SOLR_SSL_(KEY|TRUST)_STORE_PASSWORD=")
		{
			$content = $content.Substring(0, $content.IndexOf('=')) + "=$SrcKeystoreSecret"
		}
		Write-Verbose "New content: $content"
	}
	Add-Content $solrincmdNewPath $content
}

$secureKeystoreSecret = ConvertTo-SecureString "secret" -AsPlainText -Force
Import-PfxCertificate -FilePath "solr-ssl.keystore.p12" -CertStoreLocation "cert:\localmachine\root" -Password $secureKeystoreSecret


Register-PSRepository -Name SitecoreGallery
# run install-sitecoreinstallationmodules

#for WMF
$feature = Get-WindowsFeature Web-Server
if (!$feature.Installed) {
	Install-WindowsFeature Web-Server
	Install-WindowsFeature Web-Mgmt-Console
	#restart
}

$feature = Get-WindowsFeature Web-Asp-Net45
if (!$feature.Installed) {
	Install-WindowsFeature Web-Asp-Net45
}

Install-SitecoreConfiguration -Path xconnect-solr.json -SolrUrl https://localhost:8983/solr -SolrRoot C:\solr\solr-6.6.2 -SolrService solr662 -CorePrefix saskqa

#install webpi
Invoke-WebRequest -Uri "https://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi" -OutFile WebPlatformInstaller_amd64_en-US.msi
.\WebPlatformInstaller_amd64_en-US.msi /quiet

& "C:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe" /install /products:WDeploy36 /AcceptEULA

#install dacfx
Invoke-WebRequest -Uri "https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x64/DacFramework.msi" -OutFile DacFramework-x64.msi
.\DacFramework-x64.msi /quiet

Invoke-WebRequest -Uri "https://download.microsoft.com/download/5/2/8/528EE32B-A63B-462A-BF86-48EDE3DDF5A6/EN/x86/DacFramework.msi" -OutFile DacFramework-x86.msi
.\DacFramework-x86.msi /quiet

# Invoke-WebRequest -Uri "https://download.microsoft.com/download/5/E/4/5E4FCC45-4D26-4CBE-8E2D-79DB86A85F09/EN/x64/DacFramework.msi" -OutFile DacFramework-x64.msi
# .\DacFramework-x64.msi /quiet

# Invoke-WebRequest -Uri "https://download.microsoft.com/download/5/E/4/5E4FCC45-4D26-4CBE-8E2D-79DB86A85F09/EN/x86/DacFramework.msi" -OutFile DacFramework-x86.msi
# .\DacFramework-x86.msi /quiet

#install CLR Types

Invoke-WebRequest -Uri "https://download.microsoft.com/download/C/1/9/C1917410-8976-4AE0-98BF-1104349EA1E6/x64/SQLSysClrTypes.msi" -OutFile SQLSysClrTypes2017-x64.msi
.\SQLSysClrTypes2017-x64.msi /quiet

# Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x64/SQLSysClrTypes.msi" -OutFile SQLSysClrTypes2016-x64.msi
# .\SQLSysClrTypes2016-x64.msi /quiet

# Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x86/SQLSysClrTypes.msi" -OutFile SQLSysClrTypes2016-x86.msi
# .\SQLSysClrTypes2016-x86.msi /quiet

#install Script Dom
# Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x64/SqlDom.msi" -OutFile SqlDom2016-x64.msi
# .\SqlDom2016-x64.msi /quiet

# Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x86/SqlDom.msi" -OutFile SqlDom2016-x86.msi
# .\SqlDom2016-x86.msi /quiet

#install SQLSMO
# Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/7/2/872BCECA-C849-4B40-8EBE-21D48CDF1456/ENU/x64/SharedManagementObjects.msi" -OutFile SharedManagementObjects-x64.msi
# .\SharedManagementObjects-x64.msi /quiet


#install .net 4.6.2
Invoke-WebRequest -Uri "https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe" -OutFile NDP462-KB3151800-x86-x64-AllOS-ENU.exe
.\NDP462-KB3151800-x86-x64-AllOS-ENU.exe /install /quiet



Install-SitecoreConfiguration -Path ./xconnect-xp0.json -Package './Sitecore 9.0.0 rev. 171002 (OnPrem)_xp0xconnect.scwdp.zip' -LicenseFile ./license.xml -XConnectCert www-dc9-cm-q1 -SqlDbPrefix "sask" -SqlServer saskpower-qadev-sqlelastic.database.windows.net -SqlAdminUser serveradmin -SqlAdminPassword saskSC9azure -SolrCorePrefix "sask" -SolrUrl "https://localhost:8983/solr"

New-WebBinding -Name sask -Protocol https -Port 443 -HostHeader sask
#associate cert with web binding