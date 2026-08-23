param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("baseline", "otel")]
    [string]$Mode,

    [string]$BaseUrl = "http://localhost:18080"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$resultDir = Join-Path $repoRoot "k6\results\$Mode"
$summaryPath = Join-Path $resultDir "summary.json"
$outputPath = Join-Path $resultDir "output.txt"
$detailedPath = Join-Path $resultDir "metrics.jsonl"
$statsPath = Join-Path $resultDir "docker-stats.jsonl"

New-Item -ItemType Directory -Force -Path $resultDir | Out-Null

$serviceA = docker compose ps -q service-a
$serviceB = docker compose ps -q service-b

if (-not $serviceA -or -not $serviceB) {
    throw "No se encontraron contenedores activos para service-a y service-b."
}

Remove-Item -Force -ErrorAction SilentlyContinue $summaryPath, $outputPath, $detailedPath, $statsPath

$statsJob = Start-Job -ScriptBlock {
    param($Path, $ContainerIds)

    while ($true) {
        $timestamp = (Get-Date).ToUniversalTime().ToString("o")
        $lines = docker stats --no-stream --format "{{json .}}" $ContainerIds

        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            $obj = $line | ConvertFrom-Json
            $obj | Add-Member -NotePropertyName timestamp -NotePropertyValue $timestamp
            $obj | ConvertTo-Json -Compress | Add-Content -Path $Path
        }

        Start-Sleep -Seconds 5
    }
} -ArgumentList $statsPath, @($serviceA, $serviceB)

try {
    $env:BASE_URL = $BaseUrl
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & k6 run `
        -e "BASE_URL=$BaseUrl" `
        --summary-export $summaryPath `
        --out "json=$detailedPath" `
        (Join-Path $repoRoot "k6\overhead-test.js") 2>&1 |
        Tee-Object -FilePath $outputPath

    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
}
finally {
    if ($previousErrorActionPreference) {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    Stop-Job $statsJob -ErrorAction SilentlyContinue | Out-Null
    Receive-Job $statsJob -ErrorAction SilentlyContinue | Out-Null
    Remove-Job $statsJob -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item Env:\BASE_URL -ErrorAction SilentlyContinue
}

exit $exitCode
