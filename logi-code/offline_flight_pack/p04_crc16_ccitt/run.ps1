$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sim = Join-Path $here 'sim'
New-Item -ItemType Directory -Force -Path $sim | Out-Null
$env:TMP = $sim
$env:TEMP = $sim
$out = Join-Path $sim 'p04_crc16_ccitt.vvp'
& iverilog -g2012 -Wall -s tb -o $out (Join-Path $here 'crc16_ccitt.sv') (Join-Path $here 'tb_crc16_ccitt.sv')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& vvp $out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
