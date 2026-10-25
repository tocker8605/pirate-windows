param(
 [string]$Godot = 'godot',
 [string]$AudioDriver = 'WASAPI',
 [switch]$Render
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$logRoot=Join-Path $projectRoot 'work\test-logs'
New-Item -ItemType Directory -Force -Path $logRoot|Out-Null
$import=& $Godot --headless --path $projectRoot --editor --import --quit 2>&1
$import|Set-Content (Join-Path $logRoot 'import.log') -Encoding utf8
if(($import-join"
") -match 'SCRIPT ERROR|ERROR:'){throw 'Project import contained errors'}
if($LASTEXITCODE -ne 0){throw 'Project import failed'}
$tests=@('smoke','combat_reference','special_effects','campaign','presentation_audio','full_audit','pool_reference','random_reference')
if($Render){$tests+='render_rop'}
$total=0
foreach($name in $tests){
 $arguments=@('--path',$projectRoot,'--script',"tests/$name.gd")
 if($name -eq 'render_rop'){$arguments+=@('--position','0,0')}else{$arguments+=@('--headless','--audio-driver',$AudioDriver)}
 $output=& $Godot @arguments 2>&1
 $status=$LASTEXITCODE
 $lines=$output|ForEach-Object{$_.ToString()}
 $lines|Set-Content (Join-Path $logRoot "$name.log") -Encoding utf8
 $result=[regex]::Match(($lines-join"`n"),'RESULT: (\d+) checks, 0 failures')
 if($status -ne 0 -or -not$result.Success -or ($lines-join"`n") -match 'SCRIPT ERROR|ERROR:|FAIL:'){throw "Validation failed: $name; see $logRoot"}
 $total+=[int]$result.Groups[1].Value
 Write-Output "$name passed ($($result.Groups[1].Value))"
}
Write-Output "All $total checks passed. Logs: $logRoot"
