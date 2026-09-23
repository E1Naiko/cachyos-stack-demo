/**
 * Cliente HTTP pequeño para mantener las llamadas a la API fuera de los componentes.
 * En desarrollo Vite puede reenviar estas rutas mediante su proxy.
 */
const API = import.meta.env.VITE_API_URL || 'http://localhost:8000'

/** Obtiene la lista de items. */
export async function fetchItems() {
  const res = await fetch(`${API}/api/items`)
  if (!res.ok) throw new Error('Error al listar items')
  return res.json()
}

/** Crea un item a partir de los campos del formulario. */
export async function createItem(data) {
  const res = await fetch(`${API}/api/items`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error('Error al crear item')
  return res.json()
}

/** Actualiza parcialmente un item existente. */
export async function updateItem(id, data) {
  const res = await fetch(`${API}/api/items/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error('Error al actualizar')
  return res.json()
}

/** Elimina un item por su identificador. */
export async function deleteItem(id) {
  const res = await fetch(`${API}/api/items/${id}`, { method: 'DELETE' })
  if (!res.ok) throw new Error('Error al eliminar')
  return res.json()
}

/** Consulta la salud de la API y de PostgreSQL. */
export async function checkHealth() {
  const res = await fetch(`${API}/health`)
  return res.json()
}
