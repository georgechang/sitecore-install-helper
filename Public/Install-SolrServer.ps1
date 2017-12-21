function Install-SolrServer {
    [CmdletBinding()]
	param(
		[string]$Path,
		[string]$DestinationPath
	)
	Invoke-WebRequest -Uri "http://mirrors.gigenet.com/apache/lucene/solr/6.6.2/solr-6.6.2.zip" -OutFile  $FilePath -UseBasicParsing
    Expand-Archive $FilePath -DestinationPath $InstallPath
    
    #get nssm

    ./nssm.exe install $Name "$Path\bin\solr.cmd" start -f -p 8983
	./nssm.exe set $Name DisplayName "Solr 6.6.2"
	./nssm.exe set $Name Description "Service for Solr 6.6.2"
}