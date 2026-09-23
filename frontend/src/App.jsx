import { useEffect, useState } from 'react'
import { fetchItems, createItem, updateItem, deleteItem, checkHealth } from './api'

// Componente principal: coordina el estado de la UI con las operaciones del cliente HTTP.

export default function App() {
  const [items, setItems] = useState([])
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [health, setHealth] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  async function load() {
    try {
      setError('')
      const data = await fetchItems()
      setItems(data)
      const h = await checkHealth()
      setHealth(h)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  async function handleCreate(e) {
    e.preventDefault()
    if (!name.trim()) return
    try {
      await createItem({ name: name.trim(), description: description.trim() || null })
      setName(''); setDescription('')
      await load()
    } catch (e) { setError(e.message) }
  }

  async function toggleDone(item) {
    try {
      await updateItem(item.id, { is_done: !item.is_done })
      await load()
    } catch (e) { setError(e.message) }
  }

  async function handleDelete(id) {
    if (!confirm('¿Eliminar este item?')) return
    try {
      await deleteItem(id)
      await load()
    } catch (e) { setError(e.message) }
  }

  return (
    <div className="container">
      <header>
        <h1>⚡ CachyOS Stack Demo</h1>
        <p className="subtitle">React + FastAPI + PostgreSQL + SQLAlchemy + Alembic</p>
        <div className="badges">
          <span className="badge">React 18 + Vite</span>
          <span className="badge">Python 3.14</span>
          <span className="badge">PostgreSQL 18</span>
          <span className="badge">SQLAlchemy 2.0</span>
          <span className="badge">Alembic</span>
        </div>
        {health && (
          <div className={`health ${health.database === 'ok' ? 'ok' : 'err'}`}>
            API: {health.status} | DB: {health.database} — <a href="http://localhost:8000/docs" target="_blank">Swagger /docs</a>
          </div>
        )}
      </header>

      {error && <div className="error">⚠️ {error} — ¿Está corriendo el backend en :8000?</div>}

      <section className="card">
        <h2>Nuevo Item</h2>
        <form onSubmit={handleCreate} className="form">
          <input
            placeholder="Nombre (ej: Configurar PyCharm)"
            value={name}
            onChange={e => setName(e.target.value)}
            required
          />
          <input
            placeholder="Descripción opcional"
            value={description}
            onChange={e => setDescription(e.target.value)}
          />
          <button type="submit">Crear</button>
        </form>
      </section>

      <section className="card">
        <div className="card-head">
          <h2>Items ({items.length})</h2>
          <button className="secondary" onClick={load}>↻ Recargar</button>
        </div>

        {loading ? <p>Cargando...</p> :
          items.length === 0 ? <p className="muted">No hay items. ¡Crea el primero!</p> :
          <ul className="list">
            {items.map(item => (
              <li key={item.id} className={item.is_done ? 'done' : ''}>
                <div className="item-main">
                  <input type="checkbox" checked={item.is_done} onChange={() => toggleDone(item)} />
                  <div>
                    <strong>{item.name}</strong>
                    {item.description && <div className="desc">{item.description}</div>}
                    <div className="meta">#{item.id} · {new Date(item.created_at).toLocaleString()}</div>
                  </div>
                </div>
                <button className="danger small" onClick={() => handleDelete(item.id)}>Eliminar</button>
              </li>
            ))}
          </ul>
        }
      </section>

      <section className="card muted-card">
        <h3>Probar Alembic</h3>
        <ol>
          <li>Edita <code>backend/app/models.py</code> y agrega una columna (ej: <code>priority = Column(Integer, default=0)</code>)</li>
          <li>En terminal: <code>alembic revision --autogenerate -m "add priority"</code></li>
          <li><code>alembic upgrade head</code> y recarga esta página</li>
        </ol>
        <h3>Comandos útiles</h3>
        <pre>curl http://localhost:8000/health
curl http://localhost:8000/api/items
psql -U devuser -h localhost -d testdb -c "\dt"</pre>
      </section>

      <footer>Hecho para CachyOS · PyCharm → apunta el interpreter a <code>backend/.venv/bin/python</code></footer>
    </div>
  )
}
