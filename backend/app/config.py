"""Configuración central de la aplicación y sus variables de entorno."""

from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    """Valores configurables de la API, cargados desde ``.env`` o el entorno."""
    DATABASE_URL: str = "postgresql://devuser:devpass@localhost:5432/testdb"
    APP_ENV: str = "development"
    SECRET_KEY: str = "dev-secret-change-me"
    CORS_ORIGINS: str = "http://localhost:5173,http://127.0.0.1:5173"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

    @property
    def cors_origins_list(self):
        """Convierte CORS_ORIGINS en una lista limpia para FastAPI."""
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

@lru_cache()
def get_settings():
    """Construye la configuración una sola vez y la reutiliza."""
    return Settings()

settings = get_settings()
