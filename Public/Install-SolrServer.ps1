function Install-SolrServer {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$Path,
		[string]$Uri = "http://mirrors.gigenet.com/apache/lucene/solr/6.6.2/solr-6.6.2.zip"
	)

	$activity = "Installing Solr Server..."
	Write-Progress -Activity $activity -Status "Downloading Solr package..."
	if ($PSCmdlet.ShouldProcess($Uri, "Downloading package")) {
		$tmp = [IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
		Invoke-WebRequest -Uri $Uri -OutFile $tmp.FullName
	}
	Write-Progress -Activity $activity -Status "Extracting Solr package to $Path..."
	if ($PSCmdlet.ShouldProcess($tmp.FullName, "Extract package")) {
		Expand-Archive $tmp.FullName -DestinationPath $Path
	}
	Write-Progress -Activity $activity -Completed
}