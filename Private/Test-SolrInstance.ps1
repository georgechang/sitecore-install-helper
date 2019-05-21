function Test-SolrInstance {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$Path,
		[string]$Uri = "https://localhost:8983"
	)
}