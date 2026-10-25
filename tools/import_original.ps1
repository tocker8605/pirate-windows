param([Parameter(Mandatory=$true)][string]$SourcePath)
$ErrorActionPreference = 'Stop'
$src = (Resolve-Path -LiteralPath $SourcePath).Path
$dest = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path "$dest\assets\images","$dest\assets\audio","$dest\data","$dest\scripts","$dest\tests" | Out-Null
Add-Type -AssemblyName System.Drawing
Get-ChildItem -LiteralPath "$src\images" -File | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    $img.Save("$dest\assets\images\$($_.BaseName).png", [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
}
$form = [System.IO.File]::ReadAllText("$src\ibank.frm",[System.Text.Encoding]::GetEncoding(949))
$frx = [System.IO.File]::ReadAllBytes("$src\ibank.frx")
foreach ($match in [regex]::Matches($form,'(?s)Begin VB.PictureBox (\w+)\s+(.*?)(?=\r?\n   End)')) {
    $pic = [regex]::Match($match.Groups[2].Value, 'Picture\s*=\s*"ibank.frx":([0-9A-Fa-f]+)')
    if (!$pic.Success) { continue }
    $offset = [Convert]::ToInt32($pic.Groups[1].Value,16)
    $length = [BitConverter]::ToInt32($frx,$offset+8)
    $stream = [System.IO.MemoryStream]::new($frx, $offset+12, $length)
    $img = [System.Drawing.Image]::FromStream($stream)
    $img.Save("$dest\assets\images\$($match.Groups[1].Value).png", [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose(); $stream.Dispose()
}
Copy-Item -Path "$src\wave\*.wav","$src\wave\*.mid" -Destination "$dest\assets\audio"
Get-ChildItem -LiteralPath "$src\event" -Filter '*.dat' | ForEach-Object {
    $events = @()
    foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
        if ($line -notmatch '^\d+,\d+,') { continue }
        $values = @($line.Split(',') | ForEach-Object { [int]$_ })
        if ($values.Count -ne 6) { throw "Invalid event: $line" }
        $events += ,$values
    }
    [System.IO.File]::WriteAllText("$dest\data\$($_.BaseName).json",(ConvertTo-Json -InputObject $events -Depth 4),[System.Text.UTF8Encoding]::new($false))
    "$($_.BaseName): $($events.Count) events"
}
Get-ChildItem -LiteralPath "$dest\assets\images" | ForEach-Object {
    $img=[System.Drawing.Image]::FromFile($_.FullName)
    "$($_.Name): $($img.Width)x$($img.Height)"
    $img.Dispose()
}

& (Join-Path $PSScriptRoot 'normalize_audio.ps1')
