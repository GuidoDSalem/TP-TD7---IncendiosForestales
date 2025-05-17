from faker import Faker
import random
import psycopg2
from psycopg2 import OperationalError
from datetime import datetime, timedelta

# Inicialización
fake = Faker('es_ES')

# Variables globales
bosques = []
partidos = []
poligonos = []
incendios = []
estaciones = []
informes = []
bomberos = []
recursos = []
tacticas = []
causas = []

DB_CONFIG = {
    "host": "localhost",
    "port": 5439,
    "database": "tp_TD7",
    "user": "postgres",
    "password": "postgres"
}

# Conexión a la base de datos
def conectar_db():
    try:
        # Conexión a la base de datos
        conn = psycopg2.connect(**DB_CONFIG)
        print("Conexión exitosa a la base de datos.")
        return conn
    except OperationalError as e:
        print(f"Error al conectar a la base de datos: {e}")
        return None

# Funciones por tabla
def poblar_partidos(cur):
    for _ in range(5):
        nombre = fake.city()
        partidos.append(nombre)
        cur.execute(
            "INSERT INTO Partidos VALUES (%s, %s, %s)",
            (nombre, random.uniform(50, 300), random.uniform(100, 1000))
        )

def poblar_bosques(cur):
    for _ in range(5):
        nombre = fake.unique.name().capitalize()
        bosques.append(nombre)
        cur.execute(
            "INSERT INTO Bosques VALUES (%s, %s)",
            (nombre, random.uniform(500, 5000))
        )

def poblar_bosques_en_partidos(cur):
    for bosque in bosques:
        cur.execute(
            "INSERT INTO BosquesEnPartidos VALUES (%s, %s)",
            (bosque, random.choice(partidos))
        )

def poblar_estaciones(cur):
    for _ in range(3):
        nombre = fake.unique.company()
        estaciones.append(nombre)
        cur.execute(
            "INSERT INTO EstacionesMetereologicas VALUES (%s, %s, %s, %s, %s, %s)",
            (nombre, random.choice(partidos), fake.street_name(), str(random.randint(1,9999)), fake.email(), fake.phone_number())
        )

def poblar_informes(cur):
    for _ in range(10):
        estacion = random.choice(estaciones)
        timestamp = fake.date_time_this_year()
        informes.append((timestamp, estacion))
        cur.execute("""
            INSERT INTO InformesMetereologicos 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            timestamp, estacion, random.choice(['N', 'S', 'E', 'O']),
            random.uniform(0, 100), random.uniform(0, 50), random.uniform(0, 70),
            random.uniform(10, 100), random.uniform(-5, 45)
        ))

def poblar_bomberos(cur):
    for i in range(1, 4):
        bomberos.append(i)
        cur.execute(
            "INSERT INTO Bomberos VALUES (%s, %s, %s, %s)",
            (i, random.choice(partidos), random.choice(['oficial', 'voluntario']), random.randint(5, 50))
        )

def poblar_poligonos_y_coordenadas(cur):
    for i in range(5):
        bosque = random.choice(bosques)
        cur.execute("INSERT INTO Poligonos (nombre_bosque) VALUES (%s) RETURNING id_poligono", (bosque,))
        id_poligono = cur.fetchone()[0]
        poligonos.append(id_poligono)
        for j in range(4):
            cur.execute("INSERT INTO Coordenadas VALUES (%s, %s, %s, %s)",
                        (random.uniform(-90, 90), random.uniform(-180, 180), id_poligono, j))

def poblar_incendios(cur):
    for _ in range(5):
        bosque = random.choice(bosques)
        ts_inicio = fake.date_time_this_year()
        ts_fin = ts_inicio + timedelta(hours=random.randint(1, 48))
        estacion = random.choice(['verano', 'otoño', 'invierno', 'primavera'])
        incendios.append((ts_inicio, bosque))
        cur.execute("""
            INSERT INTO IncendiosForestales 
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            ts_inicio, bosque, ts_fin, estacion,
            random.uniform(0, 300), random.uniform(-90, 90), random.uniform(-180, 180)
        ))

def poblar_afluencias_indices(cur):
    for bosque in bosques:
        for _ in range(3):
            fecha = fake.date_between(start_date='-1y', end_date='today')
            cur.execute("INSERT INTO AfluenciasTuristicas VALUES (%s, %s, %s)",
                        (fecha, bosque, random.randint(0, 1000)))
            cur.execute("INSERT INTO IndicesGLI VALUES (%s, %s, %s, %s, %s, %s)",
                        (fecha, bosque, random.random(), random.random()*255, random.random()*255, random.random()*255))
            cur.execute("INSERT INTO IndicesSAVI VALUES (%s, %s, %s)",
                        (fecha, bosque, round(random.uniform(0, 1), 2)))

def poblar_comportamientos(cur):
    for ts_inicio, bosque in incendios:
        for _ in range(2):
            dia = ts_inicio.date()
            hora = (ts_inicio + timedelta(minutes=random.randint(1, 60))).time()
            inf = random.choice(informes)
            cur.execute("""
                INSERT INTO ComportamientosIncendios 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                bosque, ts_inicio, dia, hora,
                random.uniform(1, 10), random.uniform(1, 20),
                random.uniform(0, 100), random.uniform(0, 100), random.uniform(0, 100),
                inf[0], inf[1]
            ))

def poblar_bomberos_en_incendios(cur):
    for ts_inicio, bosque in incendios:
        cur.execute("INSERT INTO BomberosEnIncendios VALUES (%s, %s, %s)",
                    (random.choice(bomberos), bosque, ts_inicio))

def poblar_recursos_y_usos(cur):
    for _ in range(5):
        nombre = fake.unique.word()
        recursos.append(nombre)
        cur.execute("INSERT INTO Recursos VALUES (%s, %s, %s)",
                    (nombre, random.choice(['humano', 'material']), fake.sentence()))

    for ts_inicio, bosque in incendios:
        cur.execute("INSERT INTO RecursosUtilizadosEnIncendios VALUES (%s, %s, %s, %s)",
                    (random.choice(recursos), bosque, ts_inicio, random.randint(1, 10)))

def poblar_tacticas(cur):
    for _ in range(3):
        nombre = fake.unique.word()
        tacticas.append(nombre)
        cur.execute("INSERT INTO Tacticas VALUES (%s, %s)", (nombre, fake.sentence()))

    for ts_inicio, bosque in incendios:
        cur.execute("INSERT INTO TacticasUtilizadasEnIncendios VALUES (%s, %s, %s)",
                    (random.choice(tacticas), bosque, ts_inicio))

def poblar_causas(cur):
    for _ in range(3):
        nombre = fake.unique.word()
        causas.append(nombre)
        cur.execute("INSERT INTO Causas VALUES (%s, %s, %s)",
                    (nombre, random.choice(['natural', 'artificial']), fake.sentence()))

    for ts_inicio, bosque in incendios:
        cur.execute("INSERT INTO CausasIncendios VALUES (%s, %s, %s)",
                    (random.choice(causas), bosque, ts_inicio))

# Super función
def poblar_todo():
    conn = conectar_db()
    cur = conn.cursor()

    poblar_partidos(cur)
    poblar_bosques(cur)
    poblar_bosques_en_partidos(cur)
    poblar_estaciones(cur)
    poblar_informes(cur)
    poblar_bomberos(cur)
    poblar_poligonos_y_coordenadas(cur)
    poblar_incendios(cur)
    poblar_afluencias_indices(cur)
    poblar_comportamientos(cur)
    poblar_bomberos_en_incendios(cur)
    poblar_recursos_y_usos(cur)
    poblar_tacticas(cur)
    poblar_causas(cur)

    conn.commit()
    cur.close()
    conn.close()
def borrar_todo():
    conn = conectar_db()
    cur = conn.cursor()
    
    cur.execute("""
        TRUNCATE TABLE
            CausasIncendios,
            TacticasUtilizadasEnIncendios,
            RecursosUtilizadosEnIncendios,
            BomberosEnIncendios,
            ComportamientosIncendios,
            InformesMetereologicos,
            IncendiosForestales,
            Coordenadas,
            Poligonos,
            IndicesSAVI,
            IndicesGLI,
            AfluenciasTuristicas,
            BosquesEnPartidos,
            EstacionesMetereologicas,
            Bomberos,
            Recursos,
            Tacticas,
            Causas,
            Bosques,
            Partidos
        CASCADE;
    """)
    
    conn.commit()
    cur.close()
    conn.close()
    print("Todos los datos fueron eliminados como por un incendio bien controlado 🔥.")


# Ejecutar
if __name__ == "__main__":
    INSERTAR = True
    BORRAR = True
    
    print("Iniciando la carga de datos... 🔄")
    
    if BORRAR:
        borrar_todo()
        print("Datos eliminados correctamente. ✅")
    
    if INSERTAR:
        poblar_todo()
        print("Datos insertados correctamente. ✅")
