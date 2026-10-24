$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '../assets/audio/balloon'
New-Item -ItemType Directory -Force $root | Out-Null
# A soft latex-like pop: fast low-frequency pressure pulse and a tiny airy release.
$rate = 22050
$count = [int]($rate * .14)
$stream = [IO.File]::Create((Join-Path $root 'pop.wav'))
$writer = [IO.BinaryWriter]::new($stream)
$writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF')); $writer.Write([int](36+$count*2))
$writer.Write([Text.Encoding]::ASCII.GetBytes('WAVEfmt ')); $writer.Write([int]16)
$writer.Write([int16]1); $writer.Write([int16]1); $writer.Write([int]$rate)
$writer.Write([int]($rate*2)); $writer.Write([int16]2); $writer.Write([int16]16)
$writer.Write([Text.Encoding]::ASCII.GetBytes('data')); $writer.Write([int]($count*2))
$rng = [Random]::new(42)
for ($i=0; $i -lt $count; $i++) {
  $t = $i / $rate
  $envelope = [Math]::Min(1, $t*1800) * [Math]::Exp(-$t*47)
  $wave = [Math]::Sin(2*[Math]::PI*(240*$t-510*$t*$t)) * .7 + ($rng.NextDouble()*2-1)*.3
  $writer.Write([int16]($wave*$envelope*16000))
}
$writer.Dispose()
Write-Output "Prepared pop.wav"

# WAV copies of the CC0 Kenney effects also play on iOS (no Ogg decoder required).
$source = 'https://raw.githubusercontent.com/Calinou/kenney-interface-sounds/master'
foreach ($pair in @(@('confirmation_001','reward'), @('confirmation_004','celebrate'))) {
  $path = Join-Path $root "$($pair[1]).wav"
  if (!(Test-Path $path)) {
    Invoke-WebRequest "$source/addons/kenney_interface_sounds/$($pair[0]).wav" -OutFile $path
  }
}
if (!(Test-Path (Join-Path $root 'Kenney-LICENSE.txt'))) {
  Invoke-WebRequest "$source/LICENSE.txt" -OutFile (Join-Path $root 'Kenney-LICENSE.txt')
}

