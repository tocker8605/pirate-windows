param([string]$Version='local')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$outputRoot=Split-Path $projectRoot -Parent
$exe=Join-Path $projectRoot 'build\Pirate-II.exe'
if(-not(Test-Path -LiteralPath $exe)){throw 'Build the Windows executable first'}
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
   foreach($name in @('README-ko.txt','AUDIT-v6.txt','AUDIT-v7.txt','AUDIT-v8.txt','AUDIT-v9.txt','AUDIT-v10.txt','AUDIT-v11.txt','AUDIT-v12.txt','VALIDATION.txt')){
    $path=Join-Path $projectRoot $name
    if(Test-Path -LiteralPath $path){[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$path,$name,[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null}
   }
   foreach($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'licenses') -File){[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,('licenses/'+$file.Name),[System.IO.Compression.CompressionLevel]::Optimal)|Out-Null}
  }
 }finally{$archive.Dispose()}
 Write-Output $archivePath
}
