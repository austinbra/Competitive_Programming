$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sim = Join-Path $here 'sim'
New-Item -ItemType Directory -Force -Path $sim | Out-Null
$env:TMP = $sim
$env:TEMP = $sim
$out = Join-Path $sim 'p08_async_fifo_gray.vvp'
& iverilog -g2012 -Wall -s tb -o $out (Join-Path $here 'async_fifo_gray.sv') (Join-Path $here 'tb_async_fifo_gray.sv')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& vvp $out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

