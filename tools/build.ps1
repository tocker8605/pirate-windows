param([string]$Godot='godot',[switch]$SkipTests)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$buildRoot=Join-Path $projectRoot 'build'
New-Item -ItemType Directory -Force -Path $buildRoot|Out-Null
$engine=(Get-Command $Godot -ErrorAction Stop).Source
$guiEngine=$engine -replace '_console\.exe$','.exe'
if(-not(Test-Path -LiteralPath $guiEngine)){throw 'Install the official Godot Windows GUI executable beside the console executable.'}
$signature=Get-AuthenticodeSignature -LiteralPath $guiEngine
if(-not $signature.SignerCertificate){throw 'Use an official signed Godot executable for the portable runtime.'}
# Do not modify the official executable: icon/resource editing or PCK embedding
# changes its signed bytes. The game data is exported as a companion PCK instead.
$importOutput=& $engine --headless --path $projectRoot --editor --import --quit 2>&1
$importOutput
if(($importOutput -join [Environment]::NewLine) -match 'SCRIPT ERROR|ERROR:'){throw 'Import reported errors'}
if($LASTEXITCODE -ne 0){throw 'Import failed'}
if(-not$SkipTests){
 & (Join-Path $PSScriptRoot 'test.ps1') -Godot $engine
 if($LASTEXITCODE -ne 0){throw 'Tests failed'}
}
$pack=Join-Path $buildRoot 'Pirate-II.pck'
$exportOutput=& $engine --headless --path $projectRoot --export-pack 'Windows Desktop' $pack 2>&1
$exportOutput
if(($exportOutput -join [Environment]::NewLine) -match 'SCRIPT ERROR|ERROR:'){throw 'PCK export reported errors'}
if($LASTEXITCODE -ne 0){throw 'PCK export failed'}
$exe=Join-Path $buildRoot 'Pirate-II.exe'
Copy-Item -LiteralPath $guiEngine -Destination $exe -Force
if((Get-FileHash -LiteralPath $exe).Hash -ne (Get-FileHash -LiteralPath $guiEngine).Hash){throw 'Runtime copy does not match official executable'}
Write-Output 'Portable build ready: keep Pirate-II.exe and Pirate-II.pck together.'
