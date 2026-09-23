"""Modelos ORM: representación Python de las tablas de la base de datos."""

from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, func
from .database import Base

class Item(Base):
    """Item persistido en la tabla ``items``.

    Es el modelo interno de SQLAlchemy; las respuestas HTTP usan ``ItemOut``.
    """
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=True)
    is_done = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    def __repr__(self):
        return f"<Item id={self.id} name={self.name!r}>"
