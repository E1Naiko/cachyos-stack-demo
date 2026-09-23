# Guía del código

Este documento explica cómo funciona el ejemplo y dónde hacer cambios. El proyecto está pensado para aprender el flujo completo:

```text
React (navegador) → Vite proxy → FastAPI → SQLAlchemy → PostgreSQL
                                      ↑
                                  Alembic
```

## 1. Estructura

```text
.
├── backend/
│   ├── app/
│   │   ├── config.py       # Configuración desde variables de entorno
│   │   ├── database.py     # Engine, sesiones y Base declarativa
│   │   ├── models.py       # Modelo ORM Item y tabla items
│   │   ├── schemas.py      # Contratos de entrada/salida de la API
│   │   ├── crud.py         # Consultas y operaciones de persistencia
│   │   └── main.py         # Aplicación FastAPI y endpoints HTTP
│   ├── alembic/
│   │   ├── env.py          # Configura Alembic con los modelos de la app
│   │   └── versions/       # Historial versionado de cambios de esquema
│   └── alembic.ini         # Configuración base de Alembic
├── frontend/
│   ├── src/
│   │   ├── api.js         # Cliente HTTP del frontend
│   │   ├── App.jsx        # Estado, eventos y componentes de la pantalla
│   │   ├── App.css        # Estilos de la interfaz
│   │   └── main.jsx       # Punto de entrada de React
│   └── vite.config.js     # Servidor Vite y proxy al backend
├── docs/                  # Documentación técnica
└── setup-cachyos.sh       # Instalación automatizada para CachyOS/Arch
```

## 2. Backend, paso a paso

### Configuración: `backend/app/config.py`

`Settings` lee `DATABASE_URL`, `APP_ENV`, `SECRET_KEY` y `CORS_ORIGINS` desde el entorno o desde `backend/.env`. `get_settings()` usa `lru_cache` para crear la configuración una sola vez. Esto evita leer y validar el archivo `.env` en cada request.

`cors_origins_list` convierte la cadena separada por comas en la lista que necesita `CORSMiddleware`.

> En producción, copia `.env.example`, cambia `SECRET_KEY` y no subas `.env` al repositorio.

### Conexión: `backend/app/database.py`

- `engine`: administra la conexión/pool de SQLAlchemy.
- `SessionLocal`: fábrica de sesiones independientes por request.
- `Base`: clase de la que heredan los modelos ORM.
- `get_db()`: dependencia de FastAPI. Abre una sesión, la entrega al endpoint y siempre la cierra en `finally`.

El `pool_pre_ping=True` comprueba conexiones que podrían haber quedado obsoletas antes de reutilizarlas.

### Modelo ORM: `backend/app/models.py`

`Item` representa la tabla `items`. Cada atributo `Column` describe una columna, su tipo y restricciones. `created_at` y `updated_at` reciben la hora del servidor PostgreSQL.

El modelo ORM no es el contrato público de la API. Para eso existen los esquemas Pydantic.

### Esquemas: `backend/app/schemas.py`

- `ItemBase`: campos compartidos (`name`, `description`, `is_done`).
- `ItemCreate`: cuerpo requerido por `POST`; hereda los campos base.
- `ItemUpdate`: todos sus campos son opcionales para permitir actualizaciones parciales.
- `ItemOut`: respuesta pública, incluyendo `id` y fechas.

`from_attributes = True` permite que Pydantic 2 convierta una instancia de SQLAlchemy en una respuesta JSON.

### Persistencia: `backend/app/crud.py`

Esta capa encapsula las consultas y mantiene los endpoints pequeños:

1. `get_items` lista por `id` descendente y aplica paginación con `skip` y `limit`.
2. `get_item` busca un registro por su clave primaria.
3. `create_item` transforma el esquema en modelo, hace `add`, `commit` y `refresh`.
4. `update_item` usa `exclude_unset=True`, por lo que solo modifica campos enviados.
5. `delete_item` elimina y confirma la transacción.

Si una función no encuentra el registro, retorna `None`; `main.py` lo transforma en HTTP 404.

### API: `backend/app/main.py`

FastAPI inyecta la sesión mediante `Depends(get_db)`, valida el JSON con Pydantic y serializa las respuestas según `response_model`.

| Método | Ruta | Propósito |
|---|---|---|
| `GET` | `/` | Información rápida de la API |
| `GET` | `/health` | Comprueba que la API puede ejecutar `SELECT 1` |
| `GET` | `/api/items` | Lista items (`skip`, `limit`) |
| `POST` | `/api/items` | Crea un item; devuelve `201` |
| `GET` | `/api/items/{item_id}` | Obtiene un item |
| `PUT` | `/api/items/{item_id}` | Actualiza los campos recibidos |
| `DELETE` | `/api/items/{item_id}` | Elimina un item |

La documentación OpenAPI se genera automáticamente en `/docs` y `/redoc`.

## 3. Migraciones con Alembic

`backend/alembic/env.py` importa `Base` y todos los modelos para que `Base.metadata` conozca las tablas. También toma `DATABASE_URL` del entorno y permite ejecutar migraciones online u offline.

Flujo recomendado:

```bash
cd backend
source .venv/bin/activate
alembic revision --autogenerate -m "describe el cambio"
# revisar siempre el archivo generado
alembic upgrade head
```

`alembic/versions/001_create_items.py` es el historial inicial. Las migraciones deben permanecer en Git: son el registro reproducible del esquema. `models.py` describe el estado actual; las migraciones describen cómo llegar a él desde estados anteriores.

## 4. Frontend, paso a paso

### Entrada: `frontend/src/main.jsx`

Monta `<App />` en el elemento `#root` de `index.html` y activa `React.StrictMode` para detectar problemas comunes durante el desarrollo.

### Cliente HTTP: `frontend/src/api.js`

`API` usa `VITE_API_URL` si existe. Si no, utiliza `http://localhost:8000`. Cada helper ejecuta `fetch`, comprueba `res.ok` y devuelve JSON. En el desarrollo, también se puede dejar la variable vacía y usar el proxy de Vite.

### Pantalla: `frontend/src/App.jsx`

El componente mantiene:

- `items`: lista recibida desde la API.
- `name` y `description`: valores del formulario.
- `health`: estado de API y base de datos.
- `loading` y `error`: estados de carga y error.

`useEffect` llama a `load()` al montar la aplicación. Después de crear, actualizar o borrar, `load()` vuelve a consultar el servidor para mantener la interfaz sincronizada con PostgreSQL.

### Proxy: `frontend/vite.config.js`

Las rutas `/api` y `/health` se reenvían a `localhost:8000`. Así el navegador puede usar el mismo origen del frontend y se reducen problemas de CORS durante el desarrollo.

## 5. Ejemplo de una petición completa

Al marcar un checkbox:

1. `App.jsx` llama `updateItem(id, { is_done: true })`.
2. `api.js` envía `PUT /api/items/{id}`.
3. FastAPI valida el JSON como `ItemUpdate`.
4. `main.py` delega en `crud.update_item`.
5. SQLAlchemy actualiza `items` y hace `commit`.
6. FastAPI devuelve un `ItemOut`.
7. React vuelve a ejecutar `load()` y renderiza el resultado persistido.

## 6. Cómo extender el ejemplo

Para añadir un campo `priority`:

1. Añade la columna en `Item`.
2. Añade el campo a `ItemBase`/`ItemUpdate` según corresponda.
3. Genera y revisa una migración con Alembic.
4. Aplica `alembic upgrade head`.
5. Añade el campo al formulario y/o a la lista en `App.jsx`.
6. Actualiza `docs/ARQUITECTURA.md` si cambia el flujo.

No edites una migración ya aplicada en otros entornos; crea una nueva migración.

## 7. Decisiones y límites del demo

- No hay autenticación: `SECRET_KEY` está preparado para una futura ampliación.
- `limit` no tiene todavía una restricción adicional; en una API pública conviene validarlo con `Query(ge=1, le=100)`.
- El endpoint de health informa el error de base de datos en la respuesta; en producción se debe evitar exponer detalles internos.
- `VITE_API_URL` y la URL de Swagger en `App.jsx` apuntan a localhost porque el proyecto está pensado para desarrollo local.
