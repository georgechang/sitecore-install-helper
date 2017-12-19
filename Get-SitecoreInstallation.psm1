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
# run 

#for WMF
$feature = Get-WindowsFeature Web-Server
if (!$feature.Installed) {
	Install-WindowsFeature Web-Server
}

Install-SitecoreConfiguration -Path xconnect-solr.json -SolrUrl https://localhost:8983/solr -SolrRoot C:\solr\solr-6.6.2 -SolrService solr662 -CorePrefix sask

