# Guía Rápida - Copiar & Pegar en tu CachyOS

Tu `pacman -Syu` ya dejó todo instalado. Ahora sigue esto **en orden**.

## 1. Arreglar PostgreSQL (te falta esto, por eso el warning)

```bash
# Inicializar el cluster (SOLO una vez en la vida de la instalación)
sudo -u postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D '/var/lib/postgres/data'

# Habilitar y arrancar
sudo systemctl enable --now postgresql
sudo systemctl status postgresql
```

Si te dice `already exists` es porque ya lo hiciste, sigue igual.

## 2. Crear DB de prueba

```bash
sudo -u postgres psql -c "CREATE USER devuser WITH PASSWORD 'devpass' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE testdb OWNER devuser;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE testdb TO devuser;"

# Probar conexión
psql -U devuser -h localhost -d testdb -c "SELECT 1;"
# pass: devpass
```

> **Si te da `peer authentication failed`:** `sudo nano /var/lib/postgres/data/pg_hba.conf` cambia `peer` por `md5` en la línea `local all all` y luego `sudo systemctl restart postgresql`

## 3. Descargar y setup del repo

Opción A - Si bajaste el ZIP:
```bash
unzip cachyos-stack-demo.zip
cd cachyos-stack-demo
chmod +x setup-cachyos.sh
./setup-cachyos.sh
```

Opción B - Crear repo vacío y copiar archivos manualmente.

El script `setup-cachyos.sh` hace automáticamente:
- Crea `backend/.venv`
- `pip install -r requirements.txt`
- `npm install` en frontend
- `alembic upgrade head`

## 4. Correr (2 terminales)

**Terminal 1 - Backend:**
```bash
cd cachyos-stack-demo/backend
source .venv/bin/activate
uvicorn app.main:app --reload --port 8000
# Abre http://localhost:8000/docs
```

**Terminal 2 - Frontend:**
```bash
cd cachyos-stack-demo/frontend
npm run dev
# Abre http://localhost:5173
```

## 5. PyCharm

Instalar si no lo tienes:
```bash
# Community (gratis)
sudo pacman -S pycharm-community-edition
# o Professional desde AUR
yay -S pycharm-professional
```

Abrir PyCharm:
1. `File > Open` -> selecciona `cachyos-stack-demo`
2. `File > Settings > Project > Python Interpreter` -> `Add Interpreter` -> `Existing` -> selecciona `cachyos-stack-demo/backend/.venv/bin/python`
3. Click derecho en carpeta `backend` -> `Mark Directory as > Sources Root`
4. `Run > Edit Configurations > + > Python`
   - Name: `FastAPI`
   - Script path: `.../backend/.venv/bin/uvicorn`
   - Parameters: `app.main:app --reload --port 8000`
   - Working directory: `.../cachyos-stack-demo/backend`

Database (solo Pro): `View > Tool Windows > Database` -> `+ > PostgreSQL` -> Host `localhost`, DB `testdb`, User `devuser`, Pass `devpass`

## 6. Probar Alembic (flujo real)

```bash
cd backend
source .venv/bin/activate

# 1. Edita app/models.py, agrega por ejemplo:
#    priority = Column(Integer, default=0)

# 2. Genera migración
alembic revision --autogenerate -m "add priority column"

# 3. Revisa el archivo generado en alembic/versions/
cat alembic/versions/*.py

# 4. Aplica
alembic upgrade head

# 5. Ver en DB
psql -U devuser -h localhost -d testdb -c "\d items"
```

Listo. Ya tienes el stack completo funcionando en CachyOS.
