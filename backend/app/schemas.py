"""Esquemas Pydantic que validan los cuerpos y respuestas de la API."""

from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class ItemBase(BaseModel):
    """Campos comunes para crear y representar un item."""
    name: str
    description: Optional[str] = None
    is_done: bool = False

class ItemCreate(ItemBase):
    """Payload aceptado por ``POST /api/items``."""
    pass

class ItemUpdate(BaseModel):
    """Payload parcial aceptado por ``PUT /api/items/{id}``."""
    name: Optional[str] = None
    description: Optional[str] = None
    is_done: Optional[bool] = None

class ItemOut(ItemBase):
    """Representación pública de un item almacenado."""
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
