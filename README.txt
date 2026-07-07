# Modelado de Datos: Gestión de Incendios Forestales 🔥

Diseño e implementación de una base de datos relacional para modelar la gestión de incendios forestales: bosques, afluencia turística, brigadas de bomberos, recursos, tácticas de combate, y variables ambientales relevantes para el análisis de riesgo.

## 🎯 Alcance del modelo

El esquema relacional cubre entidades como:

- **Bosques** y su superficie
- **Afluencia turística** por bosque y fecha
- **Polígonos y coordenadas geográficas** (modelado geoespacial de áreas forestales)
- **Incendios**, **brigadas de bomberos**, **estaciones** y **recursos** disponibles
- **Tácticas de combate** aplicadas por incidente
- **Índices ambientales**: vegetación (NDVI-like), GLI y SAVI, usados como proxies de riesgo de incendio

## 🛠️ Stack

- **PostgreSQL** — modelo relacional con integridad referencial (FKs, checks)
- **Docker & Docker Compose** — entorno de base de datos reproducible
- **Python** (`psycopg2`, `Faker`) — generación de datos sintéticos realistas para poblar el modelo

## 🚀 Cómo correrlo

```bash
git clone https://github.com/GuidoDSalem/TP-TD7---IncendiosForestales.git
cd TP-TD7---IncendiosForestales

# 1. Levantar la base de datos
docker compose up -d

# 2. Crear las tablas
# Ejecutar el contenido de creacionTablas_IncendiosForestales.sql contra la DB

# 3. Poblar con datos de prueba
pip install -r requirements.txt
python mockData.py
```

## 📌 Contexto

Trabajo práctico de la materia Bases de Datos (UTDT), enfocado en diseño de esquemas relacionales para dominios geoespaciales y ambientales complejos — con foco en integridad de datos y reproducibilidad del entorno vía contenedores.



