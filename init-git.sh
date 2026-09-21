#!/bin/bash
cd "$(dirname "$0")"
git init
git add .
git commit -m "Initial commit: React + FastAPI + PostgreSQL + SQLAlchemy + Alembic (CachyOS demo)"
git branch -M main
echo "Listo. Ahora crea repo en GitHub y haz:"
echo "  git remote add origin <tu-url>"
echo "  git push -u origin main"
