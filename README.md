# CachyOS Stack Demo — React + Python + PostgreSQL + SQLAlchemy + Alembic

Repo de prueba completo listo para tu máquina CachyOS (Arch). Probado con Python 3.14, Node 26, PostgreSQL 18.

## Stack
- **Frontend:** React + Vite
- **Backend:** Python 3.14 + FastAPI + SQLAlchemy 2.0 + Alembic + psycopg2-binary
- **DB:** PostgreSQL 18
- **IDE:** PyCharm (Professional o Community)

---

## 0) Qué te faltó en tu instalación

Tu log dice:

> `"/var/lib/postgres/data" is missing or empty. Use initdb...`

En CachyOS/Arch PostgreSQL no se auto-inicializa. Tenés que hacer `initdb` y habilitar el servicio. El script `setup-cachyos.sh` ya hace todo.

---

## 1) Setup en 3 comandos (en tu máquina CachyOS)

Abre una terminal en la carpeta donde vas a clonar este repo:

```bash
# 1. Inicializar PostgreSQL (solo la primera vez en tu vida en esa máquina)
sudo -u postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D '/var/lib/postgres/data'
sudo systemctl enable --now postgresql
sudo systemctl status postgresql  # debe decir active (running)

# 2. Crear DB y usuario de prueba
sudo -u postgres psql -c "CREATE USER devuser WITH PASSWORD 'devpass' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE testdb OWNER devuser;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE testdb TO devuser;"

# 3. Ejecutar el setup automático del repo
chmod +x setup-cachyos.sh
./setup-cachyos.sh
```

El script te crea:
- `backend/.venv` con todo instalado
- `frontend/node_modules`
- Corre `alembic upgrade head` y deja la DB lista
- Te deja 2 terminales listas para correr

Si preferís hacerlo manual, seguí los pasos 2 y 3 abajo.

---

## 2) Backend manual

```bash
cd backend

# venv
python -m venv .venv
source .venv/bin/activate

# instalar deps
pip install --upgrade pip
pip install -r requirements.txt

# configurar env
cp .env.example .env
# edita .env si cambiaste usuario/pass/db
cat .env

# migrar DB (alembic)
alembic upgrade head

# correr API
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API en: http://localhost:8000  
Docs Swagger: http://localhost:8000/docs  
Health: http://localhost:8000/health

### Endpoints de prueba
- `GET /api/items` - lista items
- `POST /api/items` - crea item `{ "name": "Mi item", "description": "opcional" }`
- `GET /api/items/{id}`
- `PUT /api/items/{id}`
- `DELETE /api/items/{id}`

---

## 3) Frontend manual

```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```

Frontend en: http://localhost:5173 (proxy a backend en 8000)

---

## 4) Alembic - flujo de trabajo

```bash
cd backend
source .venv/bin/activate

# 1. Cambias app/models.py (ej: agregas una columna)
# 2. Generas migración
alembic revision --autogenerate -m "add nueva columna"

# 3. Revisas backend/alembic/versions/xxxx.py
# 4. Aplicas
alembic upgrade head

# downgrade si necesitas
alembic downgrade -1
alembic history
alembic current
```

---

## 5) PyCharm — cómo abrir este repo

### Opción A: PyCharm Professional (recomendada)
1. `File > Open` -> selecciona la carpeta `cachyos-stack-demo`
2. PyCharm detectará `backend` y `frontend` como módulos separados. Configura:

**Para el Backend:**
1. `File > Settings > Project > Python Interpreter`
2. `Add Interpreter > Add Local Interpreter > Virtualenv`
3. Selecciona `Existing` y apunta a `backend/.venv/bin/python`
4. Marca `backend` como `Sources Root`: click derecho sobre `backend` > `Mark Directory as > Sources Root`
5. `Run > Edit Configurations > + > FastAPI`
   - Module: `app.main`
   - App: `app`
   - Working directory: `/ruta/a/cachyos-stack-demo/backend`
   - Env var: `DATABASE_URL=postgresql://devuser:devpass@localhost:5432/testdb`

**Config alternativa (Uvicorn run config):**
- `+ > Python`
- Script path: `backend/.venv/bin/uvicorn`
- Parameters: `app.main:app --reload --port 8000`
- Working directory: `backend`

**Para Alembic en PyCharm:**
- Abre la terminal integrada (Alt+F12) ya con el venv activado y corre `alembic revision --autogenerate -m "..."`

**Database Tool Window (solo Pro):**
1. `View > Tool Windows > Database`
2. `+ > Data Source > PostgreSQL`
3. Host: `localhost`, Port: `5432`, DB: `testdb`, User: `devuser`, Pass: `devpass`
4. `Test Connection` -> OK. Vas a ver tus tablas `items` y `alembic_version`

### Opción B: PyCharm Community
Mismo flujo pero sin Database Tool Window. Usa `psql` o DBeaver para ver la DB:
```bash
psql -U devuser -h localhost -d testdb
\dt
SELECT * FROM items;
```

### Estructura para PyCharm
Abre el proyecto raíz. PyCharm te va a pedir 2 interpreters si abres backend y frontend. Lo normal es:
- Abrir `backend` como proyecto Python principal
- Arrastrar `frontend` y PyCharm lo detecta como proyecto JS (si tienes Node plugin)

O abre todo como un proyecto y configura:
- `Settings > Project Structure > Add Content Root` -> añade `backend` y `frontend` por separado

---

## 6) Troubleshooting CachyOS/Arch

**PostgreSQL no arranca:**
```bash
sudo systemctl status postgresql -l
sudo journalctl -u postgresql -n 50 --no-pager
# si cambiaste config
sudo -u postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D '/var/lib/postgres/data' --overwrite
```

**Error `peer authentication failed` o `password authentication failed`:**
Edita `/var/lib/postgres/data/pg_hba.conf` y cambia:
```
local   all             all                                     peer
```
por:
```
local   all             all                                     md5
```
Luego `sudo systemctl restart postgresql`

**Puerto 5432 ocupado:**
```bash
sudo ss -tulpn | grep 5432
```

**Python 3.14 y psycopg2:**
`psycopg2-binary` ya compila bien en 3.14. Si falla, alternativa: `pip install psycopg[binary]`

**Node npm permission errors:**
No uses sudo para npm. Si falla: `rm -rf frontend/node_modules package-lock.json && npm install`

---

## 7) Estructura del repo

```
cachyos-stack-demo/
├── setup-cachyos.sh          # Script automatizado para CachyOS
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py           # FastAPI app + CORS + CRUD
│   │   ├── models.py         # SQLAlchemy models (tabla items)
│   │   ├── schemas.py        # Pydantic schemas
│   │   ├── crud.py           # queries
│   │   ├── database.py       # engine, SessionLocal, Base
│   │   └── config.py         # settings desde .env
│   ├── alembic/
│   │   ├── env.py
│   │   └── versions/         # migraciones autogeneradas
│   ├── alembic.ini
│   ├── requirements.txt
│   └── .env.example
└── frontend/
    ├── src/
    │   ├── App.jsx           # UI que consume la API
    │   ├── api.js            # fetch helpers
    │   └── main.jsx
    ├── package.json
    ├── vite.config.js
    └── index.html
```

---

## 8) Comandos útiles

```bash
# Ver logs de postgres
sudo journalctl -u postgresql -f

# Conectarte a la DB
psql -U devuser -h localhost -d testdb
# o
sudo -u postgres psql -d testdb

# Resetear DB desde cero
alembic downgrade base && alembic upgrade head
# o drop y crea
sudo -u postgres psql -c "DROP DATABASE testdb; CREATE DATABASE testdb OWNER devuser;" && alembic upgrade head

# Tests rápidos de API
curl http://localhost:8000/health
curl http://localhost:8000/api/items
curl -X POST http://localhost:8000/api/items -H "Content-Type: application/json" -d '{"name":"Test","description":"hola"}'
```
