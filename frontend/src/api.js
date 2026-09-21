const API = import.meta.env.VITE_API_URL || 'http://localhost:8000'

export async function fetchItems() {
  const res = await fetch(`${API}/api/items`)
  if (!res.ok) throw new Error('Error al listar items')
  return res.json()
}

export async function createItem(data) {
  const res = await fetch(`${API}/api/items`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error('Error al crear item')
  return res.json()
}

export async function updateItem(id, data) {
  const res = await fetch(`${API}/api/items/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error('Error al actualizar')
  return res.json()
}

export async function deleteItem(id) {
  const res = await fetch(`${API}/api/items/${id}`, { method: 'DELETE' })
  if (!res.ok) throw new Error('Error al eliminar')
  return res.json()
}

export async function checkHealth() {
  const res = await fetch(`${API}/health`)
  return res.json()
}
