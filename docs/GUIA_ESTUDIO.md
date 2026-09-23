# Guía de estudio: React + FastAPI + PostgreSQL

Esta guía convierte el repositorio en un laboratorio de aprendizaje. La idea no es solo levantar la aplicación, sino entender qué problema resuelve cada capa y poder modificarla sin hacerlo a ciegas.

## 0. Objetivo del proyecto

La aplicación es una lista de items. Permite crear un item, marcarlo como terminado, eliminarlo y consultar el estado de la API y PostgreSQL.

Aunque el dominio es pequeño, el recorrido contiene piezas que aparecen en aplicaciones reales:

```text
Interfaz React
    ↓ fetch / JSON / HTTP
API FastAPI
    ↓ schemas / dependencias
Capa CRUD
    ↓ ORM / sesiones / transacciones
SQLAlchemy
    ↓ driver psycopg2
PostgreSQL

Alembic mantiene la evolución del esquema de PostgreSQL.
```

## 1. Método de estudio

No conviene leer todos los archivos de principio a fin. Sigue primero una petición completa y después estudia cada capa:

1. Abre `frontend/src/App.jsx` y localiza `handleCreate`.
2. Sigue la llamada a `createItem` en `frontend/src/api.js`.
3. Busca `POST /api/items` en `backend/app/main.py`.
4. Observa cómo FastAPI recibe `ItemCreate` y `get_db`.
5. Sigue la llamada a `crud.create_item`.
6. Comprueba cómo se crea `models.Item` y se hace `commit()`.
7. Mira `backend/app/models.py` para relacionar atributos Python con columnas SQL.
8. Revisa `schemas.py` para entender qué entra y qué sale de la API.
9. Confirma el resultado en PostgreSQL con `psql`.

Después repite el recorrido con el checkbox, que usa `PUT`, y con el botón Eliminar, que usa `DELETE`.

## 2. Preparar el laboratorio

### Arranque manual

Terminal 1, backend:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Terminal 2, frontend:

```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```

URLs útiles:

- Aplicación: `http://localhost:5173`
- Swagger: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`
- PostgreSQL: `localhost:5432`, base `testdb`

Si aún no existe PostgreSQL, sigue la sección de instalación del `README.md`. `setup-cachyos.sh` automatiza buena parte de estos pasos en CachyOS/Arch.

## 3. Módulo 1 — HTTP y JSON

### Conceptos

- **Método HTTP:** describe la intención (`GET`, `POST`, `PUT`, `DELETE`).
- **Ruta:** identifica el recurso (`/api/items` o `/api/items/3`).
- **Body:** JSON enviado, principalmente en `POST` y `PUT`.
- **Status code:** comunica el resultado (`200`, `201`, `404`).
- **Headers:** metadatos como `Content-Type: application/json`.

### Práctica

```bash
curl http://localhost:8000/
curl http://localhost:8000/health
curl http://localhost:8000/api/items

curl -X POST http://localhost:8000/api/items \
  -H 'Content-Type: application/json' \
  -d '{"name":"Estudiar HTTP","description":"Leer métodos y códigos"}'

curl -X PUT http://localhost:8000/api/items/1 \
  -H 'Content-Type: application/json' \
  -d '{"is_done":true}'

curl -i http://localhost:8000/api/items/999999
curl -X DELETE http://localhost:8000/api/items/1
```

### Preguntas

1. ¿Por qué crear devuelve `201` y no `200`?
2. ¿Qué diferencia hay entre `/api/items` y `/api/items/1`?
3. ¿Qué respuesta debería devolver la API si falta `name`?
4. ¿Qué hace `Content-Type`?

## 4. Módulo 2 — FastAPI y validación

### Archivos para leer

- `backend/app/main.py`
- `backend/app/schemas.py`

En este endpoint, las anotaciones de tipos tienen un efecto práctico:

```python
@app.post("/api/items", response_model=schemas.ItemOut, status_code=201)
def create_item(item: schemas.ItemCreate, db: Session = Depends(get_db)):
    return crud.create_item(db, item)
```

FastAPI valida el JSON con `ItemCreate`, obtiene una sesión mediante `Depends(get_db)`, ejecuta la operación y serializa el resultado como `ItemOut`.

### Ejercicios

1. Cambia `name: str` para exigir una longitud mínima usando `Field`.
2. Añade un endpoint `GET /api/items/count` que devuelva la cantidad total.
3. Cambia el mensaje de 404 y observa la respuesta en Swagger.
4. Envía un JSON sin `name` y otro con `is_done: "sí"`. Observa los errores de validación.
5. Explica por qué `ItemCreate` y `ItemOut` no son el mismo esquema.

## 5. Módulo 3 — SQL y PostgreSQL

Conéctate a la base:

```bash
psql -U devuser -h localhost -d testdb
```

Consultas para explorar:

```sql
\\dt
\\d items
SELECT * FROM items;
SELECT id, name, is_done FROM items ORDER BY id DESC;
SELECT COUNT(*) FROM items;
SELECT * FROM alembic_version;
```

Relaciona estas partes:

| Python | PostgreSQL |
|---|---|
| `Item.id` | `items.id` |
| `String(200)` | `varchar(200)` |
| `Text` | `text` |
| `Boolean` | `boolean` |
| `DateTime(timezone=True)` | timestamp con zona horaria |

### Preguntas

1. ¿Por qué `id` es clave primaria?
2. ¿Qué diferencia hay entre `nullable=False` y un valor por defecto?
3. ¿Para qué sirven los índices de `id` y `name`?
4. ¿Qué información guarda `alembic_version`?

## 6. Módulo 4 — SQLAlchemy, sesiones y CRUD

### Archivos para leer

- `backend/app/database.py`
- `backend/app/models.py`
- `backend/app/crud.py`

`engine` representa la configuración de conexión. `SessionLocal` crea sesiones. `get_db()` entrega una sesión a cada request y la cierra en `finally`.

Una creación sigue este ciclo:

```python
db_item = models.Item(**item.model_dump())
db.add(db_item)
db.commit()
db.refresh(db_item)
```

- `model_dump()` convierte el esquema Pydantic en un diccionario.
- `add()` registra el objeto en la sesión.
- `commit()` confirma la transacción en PostgreSQL.
- `refresh()` vuelve a leer el objeto para obtener `id` y fechas generadas por el servidor.

### Ejercicios

1. Cambia el orden de `created_at` en `get_items` y observa la pantalla.
2. Añade una función CRUD que busque por nombre.
3. Provoca un error antes de `commit` y explica qué pasa con la sesión.
4. Activa `echo=True` en `database.py` y observa el SQL generado.
5. Explica por qué `update_item` usa `exclude_unset=True`.

## 7. Módulo 5 — Alembic y evolución del esquema

El modelo Python no modifica automáticamente una base existente. Alembic registra esos cambios como migraciones reproducibles.

### Laboratorio: añadir prioridad

1. En `backend/app/models.py`, añade:

   ```python
   priority = Column(Integer, default=0, nullable=False)
   ```

2. Añade `priority` a `ItemBase` y `ItemUpdate` en `schemas.py`.
3. Genera la migración:

   ```bash
   cd backend
   alembic revision --autogenerate -m "add item priority"
   ```

4. Revisa el archivo generado: nunca aceptes una migración automática sin inspeccionarla.
5. Aplica el cambio:

   ```bash
   alembic upgrade head
   alembic current
   ```

6. Comprueba la columna con `psql` y luego expón el campo en React.
7. Practica volver atrás en un entorno de prueba:

   ```bash
   alembic downgrade -1
   alembic upgrade head
   ```

### Preguntas

1. ¿Qué diferencia hay entre cambiar `models.py` y crear una migración?
2. ¿Por qué no conviene editar una migración que ya fue aplicada?
3. ¿Qué significa `head`?
4. ¿Qué riesgos aparecen al añadir una columna `NOT NULL` a una tabla con datos?

## 8. Módulo 6 — React y estado

### Archivos para leer

- `frontend/src/main.jsx`
- `frontend/src/App.jsx`
- `frontend/src/api.js`
- `frontend/src/App.css`

`App` conserva el estado de la pantalla con `useState`. `useEffect` ejecuta `load()` al montar el componente. Después de cada mutación se vuelve a pedir la lista al backend, por lo que la fuente de verdad sigue siendo PostgreSQL.

### Ejercicios

1. Añade un filtro para mostrar todos, pendientes o terminados.
2. Deshabilita botones mientras se ejecuta una petición.
3. Añade un formulario para editar el nombre.
4. Muestra un mensaje diferente para error de red y error HTTP.
5. Reemplaza `confirm()` por un diálogo React.
6. Extrae la lista a un componente `ItemList` y el formulario a `ItemForm`.

### Preguntas

1. ¿Por qué React necesita `key={item.id}` al usar `map`?
2. ¿Qué diferencia hay entre el estado `loading` y `error`?
3. ¿Qué ocurre si se elimina un item sin volver a ejecutar `load()`?
4. ¿Qué ventaja aporta separar `api.js` de `App.jsx`?

## 9. Módulo 7 — CORS, proxy y configuración

El navegador aplica la política de mismo origen. FastAPI permite los orígenes definidos en `CORS_ORIGINS`. Durante el desarrollo, Vite además reenvía `/api` y `/health` al puerto 8000.

Investiga estas piezas:

- `backend/.env.example`
- `backend/app/config.py`
- `frontend/.env.example`
- `frontend/vite.config.js`

### Experimentos

1. Cambia `CORS_ORIGINS` a un valor incorrecto y observa la petición desde el navegador.
2. Cambia `VITE_API_URL` y comprueba qué URL usa `api.js`.
3. Mira la pestaña Network de las herramientas del navegador.
4. Compara una petición directa al puerto 8000 con una petición enviada mediante el proxy de Vite.

## 10. Proyecto final sugerido

Convierte la lista en una pequeña aplicación de tareas:

- `priority` con valores 1 a 5;
- fecha límite;
- filtro por estado;
- búsqueda por nombre;
- endpoint de paginación real;
- validaciones de entrada;
- pruebas del CRUD;
- migración Alembic;
- mensajes de error accesibles en React.

Orden recomendado:

1. Modelo y migración.
2. Schemas de entrada y salida.
3. Funciones CRUD.
4. Endpoints y documentación OpenAPI.
5. Cliente HTTP.
6. Estado y componentes React.
7. Pruebas y manejo de errores.

## 11. Checklist de comprensión

Antes de dar el proyecto por entendido, deberías poder explicar sin mirar la respuesta:

- qué diferencia hay entre modelo ORM y schema Pydantic;
- por qué se crea una sesión por request;
- qué hacen `commit` y `refresh`;
- cómo un endpoint termina ejecutando una consulta SQL;
- por qué Alembic es necesario aunque exista `models.py`;
- cómo llega un click de React hasta PostgreSQL;
- cómo se representa un error 404 y un error de validación;
- qué configuración debe permanecer fuera de Git;
- qué función cumple el proxy de Vite;
- cómo agregar una entidad nueva siguiendo la arquitectura existente.

## 12. Recursos dentro del repositorio

- [README principal](../README.md): instalación, CachyOS y comandos rápidos.
- [Guía de arquitectura](ARQUITECTURA.md): referencia técnica de cada módulo.
- [README del backend](../backend/README_BACKEND.md): ejecución y capas del backend.
- Swagger: `http://localhost:8000/docs` cuando el backend está encendido.
