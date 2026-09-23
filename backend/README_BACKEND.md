# Backend

El backend expone una API REST para gestionar `items`. La explicación completa de la arquitectura, el flujo de una petición y el proceso de migraciones está en [`docs/ARQUITECTURA.md`](../docs/ARQUITECTURA.md).

## Capas del código

- `app/main.py`: endpoints FastAPI, CORS y códigos HTTP.
- `app/schemas.py`: validación Pydantic de entradas y salidas.
- `app/crud.py`: consultas SQLAlchemy y transacciones.
- `app/models.py`: modelo ORM y definición de la tabla `items`.
- `app/database.py`: engine, sesiones y dependencia `get_db`.
- `app/config.py`: configuración desde `.env`.
- `alembic/`: migraciones versionadas del esquema.

## Ejecutar

### Linux/macOS

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Windows PowerShell

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Swagger está disponible en <http://localhost:8000/docs> y el estado de la conexión en <http://localhost:8000/health>.

## PyCharm

1. Abrir `backend` como proyecto o como content root.
2. Interpreter: `backend/.venv/bin/python`.
3. Run config: `uvicorn app.main:app --reload --port 8000`, con Working Directory = `backend`.

## Variables

Ver `.env.example`. No subas el archivo `.env`: puede contener credenciales.
