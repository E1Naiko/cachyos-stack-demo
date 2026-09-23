# Setup para Windows PowerShell
# Prepara el entorno de desarrollo; PostgreSQL debe estar instalado y ejecutándose.

$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

function Require-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "$Name no fue encontrado. $InstallHint"
    }
    Write-Host "  OK $Name" -ForegroundColor Green
}

Write-Host "Full Stack Demo - setup para Windows" -ForegroundColor Cyan
Write-Host "===================================="

Require-Command "node" "Instala Node.js desde https://nodejs.org/"
Require-Command "npm" "Instala Node.js desde https://nodejs.org/"
Require-Command "psql" "Agrega la carpeta bin de PostgreSQL al PATH o instala PostgreSQL."

$Python = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $Python = "py"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $Python = "python"
} else {
    Write-Error "Python no fue encontrado. Instálalo desde https://www.python.org/ y habilita Add Python to PATH."
}

Write-Host "  OK Python ($Python)" -ForegroundColor Green
Write-Host ""
Write-Host "Verifica que PostgreSQL esté ejecutándose y que exista testdb con las credenciales de backend/.env.example." -ForegroundColor Yellow
Write-Host "Si todavía no lo hiciste, consulta la sección Windows del README.md."
Write-Host ""

# Backend
Write-Host "[1/4] Preparando backend..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectDir "backend")

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "  .env creado desde .env.example"
}

if (-not (Test-Path ".venv\Scripts\python.exe")) {
    & $Python -m venv .venv
}

$VenvPython = Join-Path (Get-Location) ".venv\Scripts\python.exe"
& $VenvPython -m pip install --upgrade pip
& $VenvPython -m pip install -r requirements.txt
Write-Host "  Dependencias Python instaladas" -ForegroundColor Green

Write-Host "[2/4] Ejecutando migraciones..." -ForegroundColor Yellow
$Alembic = Join-Path (Get-Location) ".venv\Scripts\alembic.exe"
& $Alembic upgrade head
Write-Host "  Base de datos actualizada" -ForegroundColor Green

# Frontend
Write-Host "[3/4] Preparando frontend..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectDir "frontend")

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "  .env creado desde .env.example"
}

if (-not (Test-Path "node_modules")) {
    npm install
} else {
    Write-Host "  node_modules ya existe"
}
Write-Host "  Frontend preparado" -ForegroundColor Green

# Resumen
Set-Location $ProjectDir
Write-Host "[4/4] Setup completo" -ForegroundColor Yellow
Write-Host ""
Write-Host "Backend:" -ForegroundColor Cyan
Write-Host "  cd backend"
Write-Host "  .\.venv\Scripts\Activate.ps1"
Write-Host "  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
Write-Host "  Swagger: http://localhost:8000/docs"
Write-Host ""
Write-Host "Frontend, en otra terminal:" -ForegroundColor Cyan
Write-Host "  cd frontend"
Write-Host "  npm run dev"
Write-Host "  App: http://localhost:5173"
