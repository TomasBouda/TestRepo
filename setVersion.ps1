# Updates all projects with given version number
param([String]$targetVersion, [String]$releaseNotes)

# FUNCTIONS

function IncreaseVersion(){
	param(
		[Parameter(
			Position=0, 
			Mandatory=$true, 
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)
		]
		[Alias('VersionString')]
		[String]$version
	)

	$pattern = '(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:\.(\d+))?'
	$build = [convert]::ToInt32(($version | Select-String -Pattern $pattern | % {$_.matches.groups[3].Value}), 10) + 1

	return $version -replace $pattern, ('$1.$2.' + $build)
}

function Update-CsProj($csprojPath){
	Write-Host "Updating $csprojPath" -ForegroundColor Green

	$xml = New-Object XML
	$xml.Load($csprojPath)

	if(!$global:targetVersion){
		$global:targetVersion = $xml.SelectSingleNode("//AssemblyVersion").InnerText | IncreaseVersion
	}

	$xml.SelectSingleNode("//AssemblyVersion").InnerText = $global:targetVersion
	$xml.SelectSingleNode("//FileVersion").InnerText = $global:targetVersion
	$xml.SelectSingleNode("//Version").InnerText = $global:targetVersion

	$xml.SelectSingleNode("//PackageReleaseNotes").InnerText = $global:releaseNotes
	
	$xml.Save($csprojPath)
}

#END FUNCTIONS

$csProjs = Get-ChildItem $PWD -Recurse -Include *.csproj

foreach($csproj in $csProjs){
	Update-CsProj($csproj)
}

(Get-Content "$PWD\appveyor.yml") -replace 'version: (.*)\.\{build\}', ('version: '+$targetVersion+'.{build}') | Out-File "$PWD\appveyor.yml" -Encoding utf8

$desc = if(!$releasenotes) { '#description: #' } else { 'description: '+$releaseNotes+'#' };
(Get-Content "$PWD\appveyor.yml") -replace '(#)?description: (.*)#', ($desc) | Out-File "$PWD\appveyor.yml" -Encoding utf8

(Get-Content "$PWD\appveyor.yml") -replace 'tag: (.*)#', ('tag: v'+$targetVersion+'#') | Out-File "$PWD\appveyor.yml" -Encoding utf8

Write-Host "Updating versions to $targetVersion done." -ForegroundColor Green