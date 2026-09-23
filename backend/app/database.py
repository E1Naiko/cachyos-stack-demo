"""Componentes de acceso a PostgreSQL mediante SQLAlchemy."""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from .config import settings

# SQLAlchemy 2.0 - engine con pool_pre_ping para reconexión automática
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    echo=False,  # pon True para ver SQL en consola
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Entrega una sesión por request y la cierra al finalizar.

    FastAPI consume esta función como dependencia en cada endpoint que
    necesita consultar o modificar la base de datos.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
