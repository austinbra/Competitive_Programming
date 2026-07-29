$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sim = Join-Path $here 'sim'
New-Item -ItemType Directory -Force -Path $sim | Out-Null
$env:TMP = $sim
$env:TEMP = $sim
$out = Join-Path $sim 'p01_leading_one.vvp'
& iverilog -g2012 -Wall -s tb -o $out (Join-Path $here 'leading_one.sv') (Join-Path $here 'tb_leading_one.sv')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& vvp $out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
