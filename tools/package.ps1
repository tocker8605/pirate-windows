param([string]$Version='local',[string]$OutputDirectory='')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$outputRoot=if($OutputDirectory){(Resolve-Path -LiteralPath $OutputDirectory).Path}else{Split-Path $projectRoot -Parent}
$exe=Join-Path $projectRoot 'build\Pirate-II.exe'
$pack=Join-Path $projectRoot 'build\Pirate-II.pck'
if(-not(Test-Path -LiteralPath $exe) -or -not(Test-Path -LiteralPath $pack)){throw 'Run tools/build.ps1 first; both Pirate-II.exe and Pirate-II.pck are required'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach($type in @('source','windows')){
 $name = if($type -eq 'source'){"Pirate-II-Godot-source-$Version.zip"}else{"Pirate-II-Windows-$Version.zip"}
 $archivePath=Join-Path $outputRoot $name
 if(Test-Path -LiteralPath $archivePath){throw "Archive already exists: $archivePath"}
 $archive=[System.IO.Compression.ZipFile]::Open($archivePath,[System.IO.Compression.ZipArchiveMode]::Create)
 try{
  if($type -eq 'source'){
   foreach($file in Get-ChildItem -LiteralPath $projectRoot -File -Recurse -Force){
    $relative=[System.IO.Path]::GetRelativePath($projectRoot,$file.FullName)
    if($relative -match '^(\.git|\.godot|build|work)[\\/]'){continue}
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,('Pirate-II-Godot/'+$relative.Replace('\','/')),[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null
   }
  }else{
   [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$exe,'Pirate-II.exe',[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null
   [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$pack,'Pirate-II.pck',[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null
   foreach($name in @('README-ko.txt','AUDIT-v6.txt','AUDIT-v7.txt','AUDIT-v8.txt','AUDIT-v9.txt','AUDIT-v10.txt','AUDIT-v11.txt','AUDIT-v12.txt','AUDIT-v13.txt','AUDIT-v14.txt','AUDIT-v15.txt','AUDIT-v16.txt','AUDIT-v17.txt','AUDIT-v18.txt','AUDIT-v19.txt','AUDIT-v20.txt','AUDIT-v21.txt','AUDIT-v22.txt','AUDIT-v23.txt','AUDIT-v24.txt','PERFORMANCE-v24.7.txt','ENEMY-PATTERNS-v24.10.txt','ENEMY-PATTERNS-v24.11.txt','PLAYER-ENERGY-v24.12.txt','FIRE-TIMERS-v24.15.txt','FIRE-TIMERS-v24.16.txt','TIMELINE-v24.16.txt','FIRE-TIMERS-v24.17.txt','BOSS-SHIELD-v24.17.txt','CORE-LAUNCH-v24.19.txt','CORE-TARGET-v24.20.txt','CORE-RADIAL-v24.21.txt','FIRE-TIMERS-v24.21.txt','BOSS3-v24.22.txt','FIRE-TIMERS-v24.22.txt','BOSS3-ORBS-v24.23.txt','FIRE-TIMERS-v24.23.txt','BOSS3-ORB-FOLLOW-v24.24.txt','FIRE-TIMERS-v24.24.txt','FIRE-TIMERS-v24.25.txt','FIRE-TIMERS-v24.26.txt','FIRE-TIMERS-v24.27.txt','FIRE-TIMERS-v24.28.txt','FIRE-TIMERS-v24.29.txt','REFACTOR-v24.29.txt','PARTICLE-FIX-v24.30.txt','TWIN-MUZZLES-v24.31.txt','SUPPLIES-v24.32.txt','SUPPLIES-v24.33.txt','ENERGY-v24.34.txt','VALIDATION.txt')){
    $path=Join-Path $projectRoot $name
    if(Test-Path -LiteralPath $path){[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$path,$name,[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null}
   }
   foreach($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'licenses') -File){[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,('licenses/'+$file.Name),[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null}
  }
 }finally{$archive.Dispose()}
 Write-Output $archivePath
}
