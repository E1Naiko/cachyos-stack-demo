# Guía de estudio del código

Este documento explica qué hace cada parte importante del repositorio y cómo se relacionan entre sí. No es una guía de ejercicios: sirve como referencia para leer el proyecto y entender la responsabilidad de cada archivo.

## 1. Visión general

El proyecto implementa una aplicación sencilla de items usando varias capas:

```text
Navegador
  └── React: muestra la interfaz y captura eventos
        └── api.js: envía peticiones HTTP y recibe JSON
              └── FastAPI: valida peticiones y ejecuta endpoints
                    └── CRUD: expresa operaciones de negocio sobre Item
                          └── SQLAlchemy: traduce objetos Python a SQL
                                └── PostgreSQL: almacena los datos

Alembic mantiene sincronizado el esquema de PostgreSQL con los modelos.
```

Cada capa tiene una responsabilidad concreta. Por ejemplo, React no construye consultas SQL y PostgreSQL no conoce los componentes de React. La API funciona como frontera entre el navegador y la base de datos.

## 2. Estructura del repositorio

```text
cachyos-stack-demo/
├── README.md                 # Instalación, comandos y solución de problemas
├── setup-cachyos.sh          # Preparación automática en CachyOS/Arch
├── docs/
│   ├── ARQUITECTURA.md       # Referencia técnica de la aplicación
│   └── GUIA_ESTUDIO.md       # Explicación general del código
├── backend/
│   ├── app/
│   │   ├── config.py         # Configuración
│   │   ├── database.py       # Conexión y sesiones de DB
│   │   ├── models.py         # Modelos ORM
│   │   ├── schemas.py        # Validación de datos con Pydantic
│   │   ├── crud.py            # Operaciones de persistencia
│   │   └── main.py            # Aplicación y rutas FastAPI
│   ├── alembic/
│   │   └── versions/         # Historial de cambios de la base
│   ├── alembic.ini           # Configuración de Alembic
│   ├── requirements.txt      # Dependencias Python
│   └── .env.example          # Plantilla de configuración
└── frontend/
    ├── src/
    │   ├── main.jsx          # Arranque de React
    │   ├── App.jsx           # Componente principal
    │   ├── api.js            # Funciones HTTP
    │   └── App.css           # Estilos
    ├── vite.config.js        # Servidor de desarrollo y proxy
    ├── package.json          # Dependencias y scripts npm
    └── index.html            # Documento HTML inicial
```

## 3. Backend: configuración

### `backend/app/config.py`

Este archivo centraliza los valores que pueden variar entre entornos:

```python
class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://devuser:devpass@localhost:5432/testdb"
    APP_ENV: str = "development"
    SECRET_KEY: str = "dev-secret-change-me"
    CORS_ORIGINS: str = "http://localhost:5173,http://127.0.0.1:5173"
```

`BaseSettings` permite obtener esos valores desde variables de entorno o desde `backend/.env`. Los valores escritos en la clase funcionan como valores por defecto para el desarrollo.

`cors_origins_list` transforma la cadena de orígenes separados por comas en una lista. FastAPI necesita esa lista para decidir qué aplicaciones web pueden hacer peticiones al backend.

`get_settings()` está decorada con `@lru_cache`. Eso hace que la configuración se cree una sola vez y se reutilice durante la vida del proceso. La variable `settings` es la instancia que utilizan los demás módulos.

El archivo `.env` no debe subirse a Git porque normalmente contiene URLs, contraseñas o secretos. `.env.example` solo documenta el formato esperado.

## 4. Backend: conexión a PostgreSQL

### `backend/app/database.py`

Este módulo prepara SQLAlchemy:

- `engine` contiene la configuración de conexión con PostgreSQL y administra un pool de conexiones.
- `pool_pre_ping=True` comprueba que una conexión reutilizada siga viva.
- `SessionLocal` es una fábrica de sesiones.
- `Base` es la clase base para los modelos ORM.
- `get_db()` crea una sesión, la entrega al endpoint y la cierra siempre al terminar.

La función `get_db()` usa `yield` porque FastAPI la trata como una dependencia con ciclo de vida:

```python
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

Todo lo que ocurre antes de `yield` prepara el recurso. Lo que ocurre en `finally` libera el recurso incluso si el endpoint produce un error. Así no quedan sesiones abiertas innecesariamente.

## 5. Backend: modelo de datos

### `backend/app/models.py`

`Item` es un modelo ORM. Representa una fila de la tabla `items` y describe cómo se mapea cada atributo de Python a una columna de PostgreSQL:

```python
class Item(Base):
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=True)
    is_done = Column(Boolean, default=False, nullable=False)
```

- `__tablename__` indica el nombre de la tabla.
- `id` es la clave primaria y se genera para identificar cada fila.
- `name` es obligatorio y tiene como máximo 200 caracteres.
- `description` es opcional y usa texto sin una longitud corta fija.
- `is_done` indica si el item está terminado.
- `created_at` y `updated_at` registran fechas generadas por PostgreSQL.
- `index=True` solicita un índice útil para búsquedas y ordenamientos.

`__repr__` define una representación legible para depuración, por ejemplo `<Item id=3 name='Leer SQL'>`.

El modelo es una representación interna de la base de datos. No es exactamente lo mismo que el JSON que la API acepta o devuelve.

## 6. Backend: esquemas de entrada y salida

### `backend/app/schemas.py`

Los esquemas Pydantic son contratos de la API. Validan los datos que entran y controlan los datos que salen.

- `ItemBase` contiene los campos comunes.
- `ItemCreate` representa el cuerpo esperado al crear.
- `ItemUpdate` permite actualizaciones parciales: todos sus campos son opcionales.
- `ItemOut` representa un item completo en una respuesta, incluyendo `id` y fechas.

La separación entre `models.py` y `schemas.py` es importante:

- El modelo ORM está diseñado para persistir en PostgreSQL.
- El schema está diseñado para validar y serializar HTTP.
- Los clientes no deberían depender de todos los detalles internos de la base.

En `ItemOut`, `from_attributes = True` permite crear el schema a partir de un objeto SQLAlchemy y no solo a partir de un diccionario.

## 7. Backend: operaciones CRUD

### `backend/app/crud.py`

CRUD significa Create, Read, Update y Delete. Este módulo contiene las operaciones que consultan o modifican la base de datos, separadas de las rutas HTTP.

### `get_items`

```python
return db.query(models.Item) \\
    .order_by(models.Item.id.desc()) \\
    .offset(skip).limit(limit).all()
```

Construye una consulta de SQLAlchemy para obtener items, ordenarlos del más nuevo al más antiguo, saltar `skip` filas, limitar el resultado y ejecutarlo con `all()`.

### `get_item`

Busca una fila cuyo `id` coincida con el parámetro. `first()` devuelve el objeto encontrado o `None`.

### `create_item`

```python
db_item = models.Item(**item.model_dump())
db.add(db_item)
db.commit()
db.refresh(db_item)
```

Primero convierte el schema Pydantic en un diccionario. Después crea un modelo ORM, lo agrega a la sesión, confirma la transacción y vuelve a cargar el objeto para obtener los valores generados por la base, como `id` y `created_at`.

### `update_item`

Busca el objeto y usa `model_dump(exclude_unset=True)`. Esta opción es importante: solo se modifican los campos que el cliente envió. Luego `setattr` asigna cada valor, `commit()` guarda el cambio y `refresh()` actualiza el objeto.

### `delete_item`

Busca el objeto, lo marca para eliminación con `db.delete()`, confirma la transacción y devuelve el objeto eliminado. Si no existe, devuelve `None`.

El módulo CRUD no decide códigos HTTP. Si no encuentra un registro, retorna `None`; `main.py` decide convertir eso en una respuesta `404`.

## 8. Backend: aplicación y endpoints

### `backend/app/main.py`

Este es el punto de entrada de FastAPI. Crea la instancia:

```python
app = FastAPI(
    title="CachyOS Stack Demo API",
    description="React + FastAPI + PostgreSQL + SQLAlchemy + Alembic",
    version="0.1.0",
)
```

A partir de esa instancia se registran las rutas y el middleware CORS.

### CORS

`CORSMiddleware` permite que el frontend, que se ejecuta normalmente en el puerto 5173, llame al backend en el puerto 8000. La lista de orígenes permitidos procede de `settings.cors_origins_list`.

### Ruta raíz: `GET /`

Devuelve un pequeño índice con enlaces a documentación, health check y items. Sirve para comprobar rápidamente que la aplicación responde.

### Health check: `GET /health`

Recibe una sesión mediante `Depends(get_db)` y ejecuta `SELECT 1`. La respuesta distingue entre el proceso de la API y la conexión a la base de datos:

```json
{"status":"ok","database":"ok"}
```

### Listado: `GET /api/items`

FastAPI obtiene `skip`, `limit` y una sesión. El endpoint llama a `crud.get_items`. `response_model=list[schemas.ItemOut]` indica que la respuesta es una lista de objetos con la forma de `ItemOut`.

### Creación: `POST /api/items`

El parámetro `item: schemas.ItemCreate` hace que FastAPI lea y valide el JSON del body. Si es válido, se delega en CRUD y se devuelve el nuevo registro con status `201`.

### Lectura individual: `GET /api/items/{item_id}`

FastAPI convierte el segmento de URL a entero, busca el registro y lanza `HTTPException(status_code=404)` si no existe.

### Actualización: `PUT /api/items/{item_id}`

Recibe un `ItemUpdate`. Aunque la ruta usa `PUT`, la implementación acepta campos parciales porque todos los campos del schema son opcionales.

### Eliminación: `DELETE /api/items/{item_id}`

Elimina el registro y devuelve un JSON pequeño con `deleted` e `id`. Si no existe, responde con `404`.

FastAPI genera automáticamente la documentación OpenAPI en `/docs` y `/redoc` a partir de rutas, tipos, schemas y códigos de respuesta.

## 9. Migraciones con Alembic

### `backend/alembic/env.py`

Alembic necesita conocer dos cosas:

1. cómo conectarse a la base de datos;
2. qué metadatos representan el esquema actual.

`env.py` importa `Base` y los modelos para que `Base.metadata` conozca la tabla `items`. También lee `DATABASE_URL` y configura la ejecución online u offline.

### `backend/alembic/versions/001_create_items.py`

Esta migración contiene dos funciones:

- `upgrade()` crea la tabla y sus índices;
- `downgrade()` elimina los índices y la tabla.

Alembic guarda la revisión aplicada en `alembic_version`. Por eso puede saber qué migraciones faltan y ejecutar solo las necesarias.

El modelo actual y las migraciones cumplen funciones distintas:

- `models.py` describe cómo debe verse el modelo en el código actual.
- Las migraciones describen la historia de cambios necesaria para llevar una base desde una versión anterior hasta la actual.

## 10. Frontend: entrada de React

### `frontend/index.html`

Contiene el elemento vacío `<div id="root"></div>`. React usa ese elemento como punto donde montar la aplicación.

### `frontend/src/main.jsx`

`ReactDOM.createRoot` conecta React con `#root` y renderiza `<App />`. `React.StrictMode` ayuda a detectar problemas durante el desarrollo, aunque no cambia la funcionalidad que verá el usuario en producción.

## 11. Frontend: cliente HTTP

### `frontend/src/api.js`

Este módulo concentra todas las llamadas al backend. `API` toma `VITE_API_URL` del entorno y, si no existe, usa `http://localhost:8000`.

Cada función sigue el mismo patrón:

1. construye la URL;
2. ejecuta `fetch` con el método y body necesarios;
3. comprueba `res.ok`;
4. lanza un error si HTTP devuelve un status no exitoso;
5. convierte la respuesta con `res.json()`.

Las funciones son:

- `fetchItems()`: `GET /api/items`;
- `createItem(data)`: `POST /api/items`;
- `updateItem(id, data)`: `PUT /api/items/{id}`;
- `deleteItem(id)`: `DELETE /api/items/{id}`;
- `checkHealth()`: `GET /health`.

Separar estas funciones de `App.jsx` evita mezclar lógica visual con detalles de HTTP.

## 12. Frontend: componente principal

### `frontend/src/App.jsx`

`App` mantiene el estado de la interfaz con `useState`:

- `items`: datos mostrados en la lista;
- `name` y `description`: valores controlados del formulario;
- `health`: resultado del health check;
- `loading`: indica que se está cargando la lista;
- `error`: mensaje que se muestra cuando falla una petición.

`load()` obtiene los items y después consulta la salud del backend. `useEffect(() => { load() }, [])` llama a `load` cuando el componente se monta.

`handleCreate` evita el submit HTML tradicional, valida que el nombre no esté vacío, llama a `createItem`, limpia el formulario y vuelve a cargar los datos.

`toggleDone` invierte `is_done` y llama a `updateItem`.

`handleDelete` pide confirmación al usuario, llama a `deleteItem` y recarga la lista.

El JSX final representa tres zonas principales:

1. encabezado con tecnologías y estado;
2. formulario para crear items;
3. lista de items y acciones;
4. tarjeta con comandos y explicación de Alembic.

La expresión `items.map(...)` crea un elemento visual por cada item. `key={item.id}` permite que React identifique cada elemento de forma estable.

## 13. Frontend: estilos y servidor Vite

### `frontend/src/App.css`

Contiene todos los estilos de la interfaz: colores, tarjetas, botones, formulario, lista, estados terminados y mensajes de error. No contiene lógica ni comunicación con la API.

### `frontend/vite.config.js`

Configura Vite para:

- usar el plugin de React;
- escuchar en `0.0.0.0:5173`;
- aceptar el host del entorno de desarrollo;
- reenviar `/api` y `/health` a `http://localhost:8000`.

El proxy permite que el navegador acceda al frontend y que Vite reenvíe ciertas rutas al backend durante el desarrollo.

## 14. Recorrido completo de una creación

Cuando el usuario crea un item ocurre lo siguiente:

1. Escribe en los inputs; React actualiza `name` y `description`.
2. Envía el formulario; `handleCreate` intercepta el evento.
3. `api.js` envía un `POST` con JSON.
4. FastAPI encuentra la ruta `/api/items`.
5. Pydantic valida el JSON como `ItemCreate`.
6. `Depends(get_db)` proporciona una sesión SQLAlchemy.
7. `crud.create_item` crea el objeto ORM.
8. SQLAlchemy ejecuta el `INSERT` al hacer `commit()`.
9. PostgreSQL genera el id y las fechas.
10. `refresh()` trae esos valores al objeto Python.
11. FastAPI serializa el resultado como `ItemOut`.
12. React vuelve a llamar a `load()` y muestra el registro persistido.

## 15. Responsabilidad de cada capa

| Capa | Se ocupa de | No debería ocuparse de |
|---|---|---|
| React | Interfaz, estado y eventos | SQL o credenciales de DB |
| `api.js` | URLs, HTTP y JSON | Renderizar componentes |
| FastAPI | Rutas, validación HTTP y status codes | Construir la interfaz |
| Schemas | Forma y validación de datos | Ejecutar consultas |
| CRUD | Consultas y transacciones | Decidir cómo se muestra un error |
| SQLAlchemy | Mapear objetos a SQL | Saber detalles de React |
| PostgreSQL | Persistir y consultar datos | Validar la interfaz |
| Alembic | Versionar cambios del esquema | Ejecutar el CRUD normal |

Para una explicación más breve de la arquitectura y los comandos de extensión, consulta [`ARQUITECTURA.md`](ARQUITECTURA.md). Para instalar y ejecutar el proyecto, consulta el [`README.md`](../README.md).
