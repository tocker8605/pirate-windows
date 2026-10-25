param([string]$Godot='godot',[switch]$SkipTests)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'build')|Out-Null
& $Godot --headless --path $projectRoot --editor --import --quit
if($LASTEXITCODE -ne 0){throw 'Import failed'}
if(-not$SkipTests){
 & (Join-Path $PSScriptRoot 'test.ps1') -Godot $Godot
 if($LASTEXITCODE -ne 0){throw 'Tests failed'}
}
& $Godot --headless --path $projectRoot --export-release 'Windows Desktop'
if($LASTEXITCODE -ne 0){throw 'Export failed; install matching Windows export templates.'}
