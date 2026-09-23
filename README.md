# Full Stack Demo — React + FastAPI + PostgreSQL

Repositorio educativo para estudiar y probar la integración de un frontend React con una API FastAPI, PostgreSQL como base de datos, SQLAlchemy como ORM y Alembic para gestionar migraciones.

El proyecto implementa una aplicación pequeña de items para mostrar el recorrido completo de los datos:

```text
React → fetch/JSON → FastAPI → Pydantic → SQLAlchemy → PostgreSQL
                                      ↑
                                  Alembic
```

El objetivo principal no es ofrecer una aplicación terminada para producción, sino proporcionar un ejemplo completo, pequeño y modificable para entender cómo se conectan las distintas capas de un sistema web moderno.

## Propósitos del repositorio

- Entender cómo un frontend consume una API REST.
- Aprender la estructura básica de una aplicación FastAPI.
- Separar rutas, validación, lógica CRUD y persistencia.
- Ver cómo SQLAlchemy representa tablas como clases Python.
- Practicar migraciones reproducibles con Alembic.
- Observar cómo React administra estado y eventos.
- Tener una base sencilla para experimentar y agregar funcionalidades.

La documentación explicativa está en [`docs/GUIA_ESTUDIO.md`](docs/GUIA_ESTUDIO.md), donde se describe qué hace cada archivo del repositorio.

## Stack tecnológico

### Frontend

- React 18
- Vite
- JavaScript/JSX
- `fetch` para comunicación HTTP

### Backend

- Python
- FastAPI
- Uvicorn
- Pydantic
- SQLAlchemy 2
- Alembic
- `psycopg2-binary`

### Base de datos

- PostgreSQL

### Entorno opcional

El script `setup-cachyos.sh` automatiza la preparación en CachyOS/Arch, pero la aplicación no depende de CachyOS y puede ejecutarse en cualquier sistema con Python, Node.js y PostgreSQL instalados.

## Funcionalidad actual

La aplicación permite:

- listar items;
- crear items con nombre y descripción;
- marcar items como terminados;
- eliminar items;
- comprobar el estado de la API y de la conexión a PostgreSQL;
- consultar y probar la API desde Swagger.

## Estructura del repositorio

```text
.
├── backend/
│   ├── app/
│   │   ├── config.py       # Configuración desde el entorno
│   │   ├── database.py     # Engine, sesiones y Base de SQLAlchemy
│   │   ├── models.py       # Modelos ORM
│   │   ├── schemas.py      # Validación de entrada y salida
│   │   ├── crud.py         # Operaciones de persistencia
│   │   └── main.py         # Aplicación FastAPI y endpoints
│   ├── alembic/
│   │   └── versions/       # Migraciones versionadas
│   ├── alembic.ini
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── App.jsx         # Componente principal
│   │   ├── api.js          # Cliente HTTP
│   │   ├── main.jsx        # Entrada de React
│   │   └── App.css         # Estilos
│   ├── package.json
│   ├── vite.config.js
│   └── .env.example
├── docs/
│   ├── GUIA_ESTUDIO.md     # Explicación archivo por archivo
│   └── ARQUITECTURA.md      # Flujo y decisiones técnicas
├── setup-cachyos.sh
└── README.md
```

## Requisitos

- Python 3.11 o superior.
- Node.js y npm.
- PostgreSQL en ejecución.
- Git.

Las versiones exactas de las dependencias Python están en `backend/requirements.txt` y las del frontend en `frontend/package-lock.json`.

## Instalación rápida

### 1. Preparar PostgreSQL

Crea un usuario y una base de datos para el desarrollo. Los valores siguientes coinciden con `backend/.env.example`:

```bash
sudo -u postgres psql -c "CREATE USER devuser WITH PASSWORD 'devpass' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE testdb OWNER devuser;"
```

Si el usuario o la base ya existen, estos comandos pueden devolver un aviso; no es necesario recrearlos.

En CachyOS/Arch puede ser necesario inicializar y activar PostgreSQL antes:

```bash
sudo -u postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data
sudo systemctl enable --now postgresql
```

### 2. Preparar el backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
```

Inicia la API:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Preparar el frontend

En otra terminal:

```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```

La aplicación estará disponible en <http://localhost:5173>.

### Instalación automatizada en CachyOS/Arch

Si estás usando CachyOS o una distribución basada en Arch, puedes ejecutar:

```bash
chmod +x setup-cachyos.sh
./setup-cachyos.sh
```

El script comprueba dependencias, prepara PostgreSQL, crea la base de datos, instala Python y npm, y ejecuta la migración inicial.

## URLs útiles

Con el backend y frontend activos:

- Aplicación: <http://localhost:5173>
- API: <http://localhost:8000>
- Swagger/OpenAPI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>
- Health check: <http://localhost:8000/health>

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/` | Información básica de la API |
| `GET` | `/health` | Comprueba la API y PostgreSQL |
| `GET` | `/api/items` | Lista items; admite `skip` y `limit` |
| `POST` | `/api/items` | Crea un item |
| `GET` | `/api/items/{id}` | Obtiene un item por id |
| `PUT` | `/api/items/{id}` | Actualiza un item |
| `DELETE` | `/api/items/{id}` | Elimina un item |

Ejemplo:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/items
curl -X POST http://localhost:8000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Leer la documentación","description":"Entender el flujo completo"}'
```

## Migraciones con Alembic

Las migraciones representan la evolución del esquema de PostgreSQL. Para crear una migración después de modificar `backend/app/models.py`:

```bash
cd backend
source .venv/bin/activate
alembic revision --autogenerate -m "describir el cambio"
# Revisar siempre el archivo generado
alembic upgrade head
```

Comandos útiles:

```bash
alembic current      # revisión aplicada actualmente
alembic history      # historial de migraciones
alembic downgrade -1 # retrocede una migración
```

No edites una migración que ya fue aplicada en otro entorno. Crea una nueva para representar cada cambio posterior.

## Configuración

### Backend

Copia `backend/.env.example` como `backend/.env` y ajusta:

- `DATABASE_URL`: URL de conexión a PostgreSQL.
- `APP_ENV`: entorno actual.
- `SECRET_KEY`: secreto de la aplicación; debe cambiarse fuera del entorno local.
- `CORS_ORIGINS`: orígenes permitidos para el frontend.

### Frontend

`frontend/.env.example` contiene `VITE_API_URL`. Si no se define, el cliente usa `http://localhost:8000`. Durante el desarrollo, Vite también tiene un proxy para `/api` y `/health`.

Los archivos `.env` no deben subirse al repositorio.

## Documentación del código

- [`docs/GUIA_ESTUDIO.md`](docs/GUIA_ESTUDIO.md): explica qué hace cada archivo y cómo se conectan las capas.
- [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md): referencia técnica de la estructura, el flujo de datos y la extensión del proyecto.
- [`backend/README_BACKEND.md`](backend/README_BACKEND.md): instrucciones y organización del backend.

## Ideas para ampliar el demo

- Añadir prioridad o fecha de vencimiento a los items.
- Incorporar búsqueda y filtros.
- Añadir paginación más completa.
- Crear usuarios y autenticación.
- Agregar tests para la API y el frontend.
- Separar el frontend en componentes más pequeños.
- Añadir Docker o una configuración para despliegue.

## Estado del proyecto

Este repositorio es un demo educativo y de experimentación. La configuración incluida está pensada para desarrollo local, no para producción. Antes de desplegarlo habría que revisar autenticación, secretos, validación de entrada, logging, manejo de errores, CORS, migraciones y observabilidad.
