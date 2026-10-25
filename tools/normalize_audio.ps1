$ErrorActionPreference='Stop'
$audioPath = Join-Path $PSScriptRoot '..\assets\audio'
foreach($file in Get-ChildItem -LiteralPath $audioPath -Filter '*.wav') {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $offset = 12
    $format = $null
    $pcm = $null
    while($offset + 8 -le $bytes.Length) {
        $id = [System.Text.Encoding]::ASCII.GetString($bytes,$offset,4)
        $length = [BitConverter]::ToUInt32($bytes,$offset+4)
        $available = [Math]::Min([long]$length,$bytes.Length-$offset-8)
        if($id -eq 'fmt ') { $format = [byte[]]$bytes[($offset+8)..($offset+8+$available-1)] }
        if($id -eq 'data') { $pcm = [byte[]]$bytes[($offset+8)..($offset+8+$available-1)] }
        $offset += 8 + $length + ($length % 2)
    }
    if(!$format -or !$pcm) { throw "WAV chunks missing: $file" }
    if([BitConverter]::ToUInt16($format,0) -ne 1) { throw "Expected PCM: $file" }
    $format = [byte[]]$format[0..15]
    $alignment = [BitConverter]::ToUInt16($format,12)
    $pcmLength = $pcm.Length - ($pcm.Length % $alignment)
    $stream=[System.IO.MemoryStream]::new()
    $writer=[System.IO.BinaryWriter]::new($stream)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
    $writer.Write([uint32](36+$pcmLength+($pcmLength%2)))
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('WAVEfmt '))
    $writer.Write([uint32]16)
    $writer.Write($format)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
    $writer.Write([uint32]$pcmLength)
    $writer.Write($pcm,0,$pcmLength)
    if($pcmLength%2) {$writer.Write([byte]0)}
    $writer.Flush()
    [System.IO.File]::WriteAllBytes($file.FullName,$stream.ToArray())
    $writer.Dispose(); $stream.Dispose()
}
