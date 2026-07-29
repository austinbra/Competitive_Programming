$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$problems = @(
  'p08_async_fifo_gray',
  'p09_pipelined_fixed_mac',
  'p10_uart_rx'
)

foreach ($problem in $problems) {
  Write-Host "`n=== $problem ==="
  & (Join-Path $root $problem 'run.ps1')
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

