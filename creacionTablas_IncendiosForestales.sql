-- Tabla Bosques
CREATE TABLE Bosques (
    nombre TEXT PRIMARY KEY,
    superficie numeric CHECK (superficie >= 0)
);

-- Tabla AfluenciasTuristicas
CREATE TABLE AfluenciasTuristicas (
    fecha DATE check (fecha <= CURRENT_DATE),
    nombre_bosque TEXT,
    cant_turistas INTEGER check (cant_turistas >= 0),
    PRIMARY KEY (fecha, nombre_bosque),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);

-- Tabla Polígonos
CREATE TABLE Poligonos (
    id_poligono SERIAL PRIMARY KEY,
    nombre_bosque TEXT,
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);

-- Tabla Coordenadas
CREATE TABLE Coordenadas (
    latitud NUMERIC,
    longitud NUMERIC,
    id_poligono INTEGER,
    n_coordenadas INTEGER,
    PRIMARY KEY (latitud, longitud),
    FOREIGN KEY (id_poligono) REFERENCES Poligonos(id_poligono)
);

-- Tabla IncendiosForestales
CREATE TABLE IncendiosForestales (
    ts_inicio TIMESTAMP check (ts_inicio <= CURRENT_DATE),
    nombre_bosque TEXT,
    ts_fin TIMESTAMP check (ts_fin > ts_inicio),
    estacion TEXT CHECK (estacion IN ('verano', 'otoño', 'invierno', 'primavera')),
    hect_quemadas NUMERIC CHECK (hect_quemadas >= 0),
    latitud_inicio NUMERIC,
    longitud_inicio NUMERIC,
    PRIMARY KEY (ts_inicio, nombre_bosque),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);



-- Tabla IndicesGLI
CREATE TABLE IndicesGLI (
    fecha DATE check (fecha <= CURRENT_DATE),
    nombre_bosque TEXT,
    valor_gli numeric CHECK (valor_gli>=-1 and valor_gli<=1),
    valor_rojo numeric CHECK (valor_rojo>=0 and valor_rojo<=1),
    valor_azul numeric CHECK (valor_azul>=0 and valor_azul<=1),
    valor_verde numeric CHECK (valor_verde>=0 and valor_verde<=1),
    PRIMARY KEY (fecha, nombre_bosque),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);

-- Tabla IndicesSAVI
CREATE TABLE IndicesSAVI (
    fecha DATE check (fecha <= CURRENT_DATE),
    nombre_bosque TEXT,
    valor_savi NUMERIC CHECK (valor_savi>=0 and valor_savi<=1),
    PRIMARY KEY (fecha, nombre_bosque),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);

-- Tabla Partidos
CREATE TABLE Partidos (
    nombre TEXT PRIMARY KEY,
    densidad_poblacional numeric check (densidad_poblacional >= 0),
    superficie_total numeric check (superficie_total >= 0)
);

-- Tabla BosquesEnPartidos
CREATE TABLE BosquesEnPartidos (
    nombre_bosque TEXT,
    nombre_partido TEXT,
    PRIMARY KEY (nombre_bosque, nombre_partido),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre),
    FOREIGN KEY (nombre_partido) REFERENCES Partidos(nombre)
);

-- Tabla EstacionesMetereológicas
CREATE TABLE EstacionesMetereologicas (
    nombre TEXT PRIMARY KEY,
    nombre_partido TEXT,
    calle TEXT,
    numero TEXT,
    mail TEXT,
    telefono TEXT,
    FOREIGN KEY (nombre_partido) REFERENCES Partidos(nombre)
);

-- Tabla InformesMetereológicos
CREATE TABLE InformesMetereologicos (
    timestamp TIMESTAMP check (timestamp <= CURRENT_DATE),
    nombre_estacionMetereologica TEXT,
    dir_viento TEXT,
    vel_viento NUMERIC,
    precipitacion_6h NUMERIC CHECK (precipitacion_6h >= 0),
    precipitacion12_h NUMERIC CHECK (precipitacion12_h >= 0),
    humedad NUMERIC CHECK (humedad BETWEEN 0 AND 100),
    temperatura NUMERIC,
    PRIMARY KEY (timestamp, nombre_estacionMetereologica),
    FOREIGN KEY (nombre_estacionMetereologica) REFERENCES EstacionesMetereologicas(nombre)
);

-- Tabla ComportamientosIncendios
CREATE TABLE ComportamientosIncendios (
    nombre_bosque TEXT,
    inicio_incendio TIMESTAMP,
    dia DATE,
    hora TIME,
    longitud_llamas NUMERIC,
    altura_llamas NUMERIC,
    humedad_comb_FFMC NUMERIC,
    humedad_comb_DMC NUMERIC,
    humedad_comb_DC NUMERIC,
    timestamp_informeMeteorologico TIMESTAMP,
    nombre_estacionMetereologica TEXT,
    PRIMARY KEY (nombre_bosque, inicio_incendio, dia, hora),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, ts_inicio),
    FOREIGN KEY (timestamp_informeMeteorologico, nombre_estacionMetereologica)
        REFERENCES InformesMetereologicos(timestamp, nombre_estacionMetereologica)
);

-- Tabla Bomberos
CREATE TABLE Bomberos (
    nro_brigada INTEGER PRIMARY KEY,
    nombre_partido TEXT,
    tipo TEXT NOT NULL CHECK (tipo IN ('oficial', 'voluntario')),
    cantidad_bomberos INTEGER CHECK (cantidad_bomberos >= 0),
    FOREIGN KEY (nombre_partido) REFERENCES Partidos(nombre)
);

-- Tabla BomberosEnIncendios
CREATE TABLE BomberosEnIncendios (
    nro_brigada INTEGER,
    nombre_bosque TEXT,
    inicio_incendio TIMESTAMP,
    PRIMARY KEY (nro_brigada, nombre_bosque, inicio_incendio),
    FOREIGN KEY (nro_brigada) REFERENCES Bomberos(nro_brigada),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, ts_inicio)
);

-- Tabla Recursos
CREATE TABLE Recursos (
    nombre TEXT PRIMARY KEY,
    tipo TEXT CHECK (tipo IN ('humano', 'material')),
    descripcion TEXT
);

-- Tabla RecursosUtilizadosEnIncendios
CREATE TABLE RecursosUtilizadosEnIncendios (
    nombre_recurso TEXT,
    nombre_bosque TEXT,
    inicio_incendio TIMESTAMP,
    cantidad INTEGER,
    PRIMARY KEY (nombre_recurso, nombre_bosque, inicio_incendio),
    FOREIGN KEY (nombre_recurso) REFERENCES Recursos(nombre),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, ts_inicio)
);

-- Tabla Tácticas
CREATE TABLE Tacticas (
    nombre TEXT PRIMARY KEY,
    descripcion TEXT
);

-- Tabla TácticasUtilizadasEnIncendios
CREATE TABLE TacticasUtilizadasEnIncendios (
    nombre_tactica TEXT,
    nombre_bosque TEXT,
    inicio_incendio TIMESTAMP,
    PRIMARY KEY (nombre_tactica, nombre_bosque, inicio_incendio),
    FOREIGN KEY (nombre_tactica) REFERENCES Tacticas(nombre),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, ts_inicio)
);

-- Tabla Causas
CREATE TABLE Causas (
    nombre TEXT PRIMARY KEY,
    tipo TEXT CHECK (tipo in ('artificial', 'natural')),
    descripcion TEXT
);

-- Tabla CausasIncendios
CREATE TABLE CausasIncendios (
    nombre_causa TEXT,
    nombre_bosque TEXT,
    inicio_incendio TIMESTAMP,
    PRIMARY KEY (nombre_causa, nombre_bosque, inicio_incendio),
    FOREIGN KEY (nombre_causa) REFERENCES Causas(nombre),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, ts_inicio)
);
