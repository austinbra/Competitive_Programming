$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sim = Join-Path $here 'sim'
New-Item -ItemType Directory -Force -Path $sim | Out-Null
$env:TMP = $sim
$env:TEMP = $sim
$out = Join-Path $sim 'p07_axil_regfile4.vvp'
& iverilog -g2012 -Wall -s tb -o $out (Join-Path $here 'axil_regfile4.sv') (Join-Path $here 'tb_axil_regfile4.sv')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& vvp $out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
