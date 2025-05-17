import random
from faker import Faker
import psycopg2
from datetime import datetime, timedelta
from psycopg2 import OperationalError

fake = Faker()

# Configuración DB
DB_CONFIG = {
    "host": "localhost",
    "port": 5439,
    "database": "tp_TD7",
    "user": "postgres",
    "password": "postgres"
}

N_BOSQUES = 10
N_PARTIDOS = 5
N_BOMBEROS = 3
N_INCENDIOS = 5
N_POLIGONOS = 15
N_TACTICAS = 3
N_RECURSOS = 3
N_ESTACIONES = 3
N_COMPORTAMIENTOS = 5
N_INDICES_VEG = 5
N_INDICES_GLI = 5
N_INDICES_SAVI = 5

# ----------------------------
# Generar datos
# ----------------------------
bosques = [(f"Bosque_{i}", round(random.uniform(100, 5000), 2)) for i in range(N_BOSQUES)]
partidos = [(f"Partido_{i}", round(random.uniform(50, 500), 2), round(random.uniform(1000, 50000), 2)) for i in range(N_PARTIDOS)]
bosques_en_partidos = [(b[0], random.choice(partidos)[0]) for b in bosques]

poligonos = [(p, fake.color_name(), bosques[p % len(bosques)][0]) for p in range(N_POLIGONOS)]
coordenadas = []
for p in poligonos:
    for _ in range(15):
        lat, lon = round(fake.latitude(), 6), round(fake.longitude(), 6)
        coordenadas.append((lat, lon, p[0]))

estaciones = [(f"Estacion_{i}", random.choice(partidos)[0], fake.address(), fake.street_name(), fake.building_number(), fake.email(), fake.phone_number()) for i in range(3)]

informes_met = []
for i in range(5):
    t = fake.date_time_between(start_date='-1y', end_date='now')
    e = random.choice(estaciones)[0]
    informes_met.append((t, e, random.choice(["N", "S", "E", "O"]), random.uniform(0, 100), random.uniform(0, 50), random.uniform(0, 80), random.uniform(0, 100), random.uniform(-10, 45)))

incendios = []
for b in bosques:
    inicio = fake.date_time_between(start_date='-6M', end_date='-1d')
    fin = inicio + timedelta(days=random.randint(1, 5))
    estacion = random.choice(estaciones)[0]
    hect = round(random.uniform(10, 500), 2)
    causa = random.choice(["natural", "humana", "desconocida"])
    incendios.append((b[0], inicio, fin, estacion, hect, causa))

comportamientos = []
for inc in incendios:
    for dia in range(1, 3):
        for hora in [10, 15]:
            comportamiento = (
                inc[0], inc[1], dia, hora,
                round(random.uniform(1, 10), 2),
                round(random.uniform(1, 10), 2),
                round(random.uniform(50, 100), 2),
                round(random.uniform(10, 50), 2),
                round(random.uniform(5, 40), 2),
                random.choice(informes_met)[0]
            )
            comportamientos.append(comportamiento)

indices_veg = [(fake.date_between(start_date='-6M', end_date='today'), b[0]) for b in bosques]
indices_gli = [(iv[0], iv[1], random.random(), random.random(), random.random(), random.random()) for iv in indices_veg]
indices_savi = [(iv[0], iv[1], random.random()) for iv in indices_veg]

bomberos = [(i, random.choice(["Voluntario", "Oficial"]), random.randint(10, 100), random.choice(partidos)[0]) for i in range(1, 4)]
bomberos_inc = [(b[0], inc[0], inc[1]) for b in bomberos for inc in incendios[:2]]

recursos = [(f"Recurso_{i}", random.choice(["Camioneta", "Helicoptero", "Tanque"]), fake.text()) for i in range(3)]
recursos_inc = [(r[0], inc[0], inc[1], random.randint(1, 10)) for r in recursos for inc in incendios[:2]]

tacticas = [(f"Tactica_{i}", fake.text()) for i in range(3)]
tacticas_inc = [(t[0], inc[0], inc[1]) for t in tacticas for inc in incendios[:2]]

# ----------------------------
# Funciones de base de datos
# ----------------------------

def vaciar_tablas(conn):
    with conn.cursor() as cur:
        cur.execute("""
            DO $$
            BEGIN
                EXECUTE 'TRUNCATE TABLE 
                    TacticasUtilizadasEnIncendio,
                    RecursosUtilizadosEnIncendio,
                    BomberosIncendio,
                    IndicesSAVI,
                    IndicesGLI,
                    IndicesVegetacion,
                    ComportamientosIncendio,
                    IncendiosForestales,
                    InformesMetereologicos,
                    EstacionesMetereologicas,
                    BosquesEnPartidos,
                    Coordenadas,
                    Poligonos,
                    Tacticas,
                    Recursos,
                    Bomberos,
                    Partidos,
                    Bosques
                    RESTART IDENTITY CASCADE';
            END $$;
        """)
        conn.commit()

def insertar_datos(conn):
    with conn.cursor() as cur:
        cur.executemany("INSERT INTO Bosques VALUES (%s, %s)", bosques)
        cur.executemany("INSERT INTO Partidos VALUES (%s, %s, %s)", partidos)
        cur.executemany("INSERT INTO BosquesEnPartidos VALUES (%s, %s)", bosques_en_partidos)
        cur.executemany("INSERT INTO Poligonos VALUES (%s, %s, %s)", poligonos)
        cur.executemany("INSERT INTO Coordenadas VALUES (%s, %s, %s)", coordenadas)
        cur.executemany("INSERT INTO EstacionesMetereologicas VALUES (%s, %s, %s, %s, %s, %s, %s)", estaciones)
        cur.executemany("INSERT INTO InformesMetereologicos VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", informes_met)
        cur.executemany("INSERT INTO IncendiosForestales VALUES (%s, %s, %s, %s, %s, %s)", incendios)
        cur.executemany("INSERT INTO ComportamientosIncendio VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", comportamientos)
        cur.executemany("INSERT INTO IndicesVegetacion VALUES (%s, %s)", indices_veg)
        cur.executemany("INSERT INTO IndicesGLI VALUES (%s, %s, %s, %s, %s, %s)", indices_gli)
        cur.executemany("INSERT INTO IndicesSAVI VALUES (%s, %s, %s)", indices_savi)
        cur.executemany("INSERT INTO Bomberos VALUES (%s, %s, %s, %s)", bomberos)
        cur.executemany("INSERT INTO BomberosIncendio VALUES (%s, %s, %s)", bomberos_inc)
        cur.executemany("INSERT INTO Recursos VALUES (%s, %s, %s)", recursos)
        cur.executemany("INSERT INTO RecursosUtilizadosEnIncendio VALUES (%s, %s, %s, %s)", recursos_inc)
        cur.executemany("INSERT INTO Tacticas VALUES (%s, %s)", tacticas)
        cur.executemany("INSERT INTO TacticasUtilizadasEnIncendio VALUES (%s, %s, %s)", tacticas_inc)
        conn.commit()
        

def verificar_conexion(config):
    try:
        conn = psycopg2.connect(**config)
        conn.close()
        return True
    except OperationalError as e:
        print(f"❌ No se pudo conectar: {e}")
        return False

def vaciar_todas_las_tablas(conn):
    with conn.cursor() as cur:
        tablas = [
            "TacticasUtilizadasEnIncendio", "Tacticas", "RecursosUtilizadosEnIncendio", "Recursos",
            "BomberosIncendio", "Bomberos", "ComportamientosIncendio", "IncendiosForestales",
            "InformesMetereologicos", "EstacionesMetereologicas", "BosquesEnPartidos",
            "IndicesGLI", "IndicesSAVI", "IndicesVegetacion", "Coordenadas", "Poligonos",
            "Partidos", "bosques"
        ]
        for tabla in tablas:
            cur.execute(f"DROP TABLE public.{tabla.lower()} CASCADE;")
        conn.commit()
    print("🧹 Todas las tablas han sido vaciadas.")

# ----------------------------
# Ejecución
# ----------------------------
if __name__ == "__main__":
    print("Inicio del programa")
    
    VACIAR = True
    ELIMINAR = True
    INGRESAR = False
    
    
    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            conexion = verificar_conexion(DB_CONFIG)
            if conexion:
                print("CONEXIO  EXITOSA")
            else:
                print("ERROR - no se pudo conectar al DDBB")
    except Exception as e:
        print(f"💥 Error: {e}")
        
    if VACIAR:
        try:
            with psycopg2.connect(**DB_CONFIG) as conn:
                print("🧹 Vaciando tablas...")
                vaciar_todas_las_tablas(conn)
        except Exception as e:
            print(f"💥 Error: {e}")
            
    if ELIMINAR:
        try:
            with psycopg2.connect(**DB_CONFIG) as conn:
                vaciar_todas_las_tablas(conn)
        except Exception as e:
            print(f"💥 Error: {e}")
            
    if INGRESAR:
        try:
            with psycopg2.connect(**DB_CONFIG) as conn:
                insertar_datos(conn)
                print("✅ Datos insertados correctamente.")
        except Exception as e:
            print(f"💥 Error: {e}")
        
        
