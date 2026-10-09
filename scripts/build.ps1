$ErrorActionPreference = "Stop"
Push-Location (Join-Path $PSScriptRoot "..")
try {
    wally install
    if ($LASTEXITCODE -ne 0) { throw "Wally install failed." }
    New-Item -ItemType Directory -Force -Path "dist" | Out-Null
    darklua process src/main.luau dist/redliner.lua --config .darklua.json
    if ($LASTEXITCODE -ne 0) { throw "Darklua build failed." }
    if (!(Test-Path -LiteralPath "dist/redliner.lua") -or (Get-Item "dist/redliner.lua").Length -eq 0) {
        throw "The build artifact is missing or empty."
    }
} finally {
    Pop-Location
}
