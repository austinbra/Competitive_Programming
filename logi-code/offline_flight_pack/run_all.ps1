$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$problems = @(
  'p01_leading_one',
  'p02_uart_tx',
  'p03_spi_master_mode0',
  'p04_crc16_ccitt',
  'p05_fir4',
  'p06_unsigned_divider',
  'p07_axil_regfile4'
)

foreach ($problem in $problems) {
  Write-Host "`n=== $problem ==="
  & (Join-Path $root $problem 'run.ps1')
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
