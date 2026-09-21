#!/bin/bash
set -e

# Setup automatizado para CachyOS / Arch
# Stack: React + Python + PostgreSQL + SQLAlchemy + Alembic

echo "🚀 Setup CachyOS Stack Demo"
echo "============================"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${YELLOW}[1/7] Verificando dependencias del sistema...${NC}"
for cmd in python psql node npm git; do
  if command -v $cmd &> /dev/null; then
    echo "  ✓ $cmd: $( $cmd --version 2>&1 | head -n1 )"
  else
    echo -e "  ${RED}✗ $cmd no encontrado. Instala con: sudo pacman -S $cmd${NC}"
    exit 1
  fi
done

echo ""
echo -e "${YELLOW}[2/7] Verificando PostgreSQL...${NC}"
if sudo systemctl is-active --quiet postgresql 2>/dev/null; then
  echo "  ✓ PostgreSQL ya está corriendo"
else
  echo "  ⚠ PostgreSQL no está activo. Intentando inicializar..."
  if [ ! -s "/var/lib/postgres/data/PG_VERSION" ]; then
    echo "  → Inicializando cluster..."
    sudo -u postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D '/var/lib/postgres/data'
  fi
  echo "  → Habilitando e iniciando servicio..."
  sudo systemctl enable --now postgresql
  sleep 2
fi
sudo systemctl status postgresql --no-pager -l | head -n 20 || true

echo ""
echo -e "${YELLOW}[3/7] Creando usuario y base de datos...${NC}"
# Crear usuario devuser si no existe
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='devuser'" | grep -q 1; then
  echo "  ✓ Usuario devuser ya existe"
else
  sudo -u postgres psql -c "CREATE USER devuser WITH PASSWORD 'devpass' CREATEDB;"
  echo "  ✓ Usuario devuser creado"
fi

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw testdb; then
  echo "  ✓ Base de datos testdb ya existe"
else
  sudo -u postgres psql -c "CREATE DATABASE testdb OWNER devuser;"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE testdb TO devuser;"
  echo "  ✓ Base testdb creada"
fi

echo ""
echo -e "${YELLOW}[4/7] Configurando backend Python...${NC}"
cd "$PROJECT_DIR/backend"

if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "  ✓ .env creado desde .env.example"
fi

if [ ! -d ".venv" ]; then
  echo "  → Creando venv..."
  python -m venv .venv
fi

echo "  → Activando venv e instalando dependencias..."
source .venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo "  ✓ Dependencias Python instaladas"

echo ""
echo -e "${YELLOW}[5/7] Ejecutando migraciones Alembic...${NC}"
# Dar permisos al alembic si necesita crear versión
alembic upgrade head
echo "  ✓ DB migrada a head"
echo "  → Estado actual:"
alembic current
psql "postgresql://devuser:devpass@localhost:5432/testdb" -c "\dt" || sudo -u postgres psql -d testdb -c "\dt"

echo ""
echo -e "${YELLOW}[6/7] Configurando frontend React...${NC}"
cd "$PROJECT_DIR/frontend"
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "  ✓ frontend/.env creado"
fi
if [ ! -d "node_modules" ]; then
  echo "  → npm install (puede tardar 1-2 min)..."
  npm install
else
  echo "  ✓ node_modules ya existe"
fi
echo "  ✓ Frontend listo"

echo ""
echo -e "${YELLOW}[7/7] Verificación final...${NC}"
cd "$PROJECT_DIR"
# Test rápido de imports python
source backend/.venv/bin/activate
python -c "import sqlalchemy, alembic, fastapi, psycopg2; print('  ✓ Python deps OK')"
deactivate || true

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Setup completo!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Para correr el proyecto abre 2 terminales:"
echo ""
echo -e "${YELLOW}Terminal 1 - Backend:${NC}"
echo "  cd $PROJECT_DIR/backend"
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --reload --port 8000"
echo "  → http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}Terminal 2 - Frontend:${NC}"
echo "  cd $PROJECT_DIR/frontend"
echo "  npm run dev"
echo "  → http://localhost:5173"
echo ""
echo -e "${YELLOW}PostgreSQL:${NC}"
echo "  psql -U devuser -h localhost -d testdb  # pass: devpass"
echo "  sudo -u postgres psql -d testdb         # sin pass"
echo ""
echo -e "${YELLOW}PyCharm:${NC}"
echo "  1. File > Open > $PROJECT_DIR"
echo "  2. Interprete: apunta a $PROJECT_DIR/backend/.venv/bin/python"
echo "  3. Mark backend/ como Sources Root"
echo ""
