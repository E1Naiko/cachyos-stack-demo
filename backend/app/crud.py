"""Operaciones de persistencia para la entidad Item."""

from sqlalchemy.orm import Session
from . import models, schemas

def get_items(db: Session, skip: int = 0, limit: int = 100):
    """Devuelve items paginados, del más nuevo al más antiguo."""
    return db.query(models.Item).order_by(models.Item.id.desc()).offset(skip).limit(limit).all()

def get_item(db: Session, item_id: int):
    """Busca un item por id o devuelve ``None`` si no existe."""
    return db.query(models.Item).filter(models.Item.id == item_id).first()

def create_item(db: Session, item: schemas.ItemCreate):
    """Crea, confirma y devuelve un item nuevo."""
    db_item = models.Item(**item.model_dump())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

def update_item(db: Session, item_id: int, item_update: schemas.ItemUpdate):
    """Aplica solo los campos enviados y devuelve el item actualizado."""
    db_item = get_item(db, item_id)
    if not db_item:
        return None
    update_data = item_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_item, field, value)
    db.commit()
    db.refresh(db_item)
    return db_item

def delete_item(db: Session, item_id: int):
    """Elimina un item y lo devuelve; retorna ``None`` si no existe."""
    db_item = get_item(db, item_id)
    if not db_item:
        return None
    db.delete(db_item)
    db.commit()
    return db_item
