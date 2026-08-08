param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = "Stop"

$RuntimeTool = "D:\CAGE\xcsv-ai-continuity\tools\xcsv-continuity.ps1"
if (-not (Test-Path -LiteralPath $RuntimeTool)) {
    throw "XCSV continuity runtime tool is missing: $RuntimeTool"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $RuntimeTool @Args
