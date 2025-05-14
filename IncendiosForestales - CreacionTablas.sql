CREATE TABLE Bosques (
    nombre VARCHAR(100) PRIMARY KEY,
    superficie FLOAT
);

CREATE TABLE Poligonos (
    ID_poligono INT PRIMARY KEY,
    color VARCHAR(50),
    nombre_bosque VARCHAR(100),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);

CREATE TABLE Coordenadas (
    latitud FLOAT,
    longitud FLOAT,
    ID_poligono INT,
    PRIMARY KEY (latitud, longitud, ID_poligono),
    FOREIGN KEY (ID_poligono) REFERENCES Poligonos(ID_poligono)
);

CREATE TABLE Partidos (
    nombre_partido VARCHAR(100) PRIMARY KEY,
    densidad_poblacional FLOAT,
    superficie_total FLOAT
);

CREATE TABLE BosquesEnPartidos (
    nombre_bosque VARCHAR(100),
    nombre_partido VARCHAR(100),
    PRIMARY KEY (nombre_bosque, nombre_partido),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre),
    FOREIGN KEY (nombre_partido) REFERENCES Partidos(nombre_partido)
);

CREATE TABLE EstacionesMetereologicas (
    nombre VARCHAR(100) PRIMARY KEY,
    nombre_partido VARCHAR(100),
    direccion VARCHAR(255),
    calle VARCHAR(100),
    numero INT,
    mail VARCHAR(100),
    telefono VARCHAR(50),
    FOREIGN KEY (nombre_partido) REFERENCES Partidos(nombre_partido)
);

CREATE TABLE InformesMetereologicos (
    timestamp TIMESTAMP PRIMARY KEY,
    nombre_estacionMetereologica VARCHAR(100),
    dir_viento VARCHAR(50),
    vel_viento FLOAT,
    precipitacion_6h FLOAT,
    precipitacion12_h FLOAT,
    humedad FLOAT,
    temperatura FLOAT,
    FOREIGN KEY (nombre_estacionMetereologica) REFERENCES EstacionesMetereologicas(nombre)
);

CREATE TABLE IncendiosForestales (
    nombre_bosque VARCHAR(100),
    inicio TIMESTAMP,
    fin TIMESTAMP,
    estacion VARCHAR(50),
    hect_quemadas FLOAT,
    tipo_causa VARCHAR(100),
    PRIMARY KEY (nombre_bosque, inicio),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);

CREATE TABLE ComportamientosIncendio (
    nombre_bosque VARCHAR(100),
    inicio_incendio TIMESTAMP,
    dia INT,
    hora INT,
    longitud_llamas FLOAT,
    altura_llamas FLOAT,
    humedad_comb_FFMC FLOAT,
    humedad_comb_DMC FLOAT,
    humedad_comb_DC FLOAT,
    timestamp_informeMeteorologico TIMESTAMP,
    PRIMARY KEY (nombre_bosque, inicio_incendio, dia, hora),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, inicio),
    FOREIGN KEY (timestamp_informeMeteorologico) REFERENCES InformesMetereologicos(timestamp)
);

CREATE TABLE IndicesVegetacion (
    fecha DATE,
    nombre_bosque VARCHAR(100),
    PRIMARY KEY (fecha, nombre_bosque),
    FOREIGN KEY (nombre_bosque) REFERENCES Bosques(nombre)
);

CREATE TABLE IndicesGLI (
    fecha DATE,
    nombre_bosque VARCHAR(100),
    valor FLOAT,
    valor_rojo FLOAT,
    valor_azul FLOAT,
    valor_verde FLOAT,
    PRIMARY KEY (fecha, nombre_bosque),
    FOREIGN KEY (fecha, nombre_bosque) REFERENCES IndicesVegetacion(fecha, nombre_bosque)
);

CREATE TABLE IndicesSAVI (
    fecha DATE,
    nombre_bosque VARCHAR(100),
    valor FLOAT,
    PRIMARY KEY (fecha, nombre_bosque),
    FOREIGN KEY (fecha, nombre_bosque) REFERENCES IndicesVegetacion(fecha, nombre_bosque)
);

CREATE TABLE Bomberos (
    nro_brigada INT PRIMARY KEY,
    tipo VARCHAR(100),
    cantidad_bomberos INT,
    nombre_partido VARCHAR(100),
    FOREIGN KEY (nombre_partido) REFERENCES Partidos(nombre_partido)
);

CREATE TABLE BomberosIncendio (
    nro_brigada INT,
    nombre_bosque VARCHAR(100),
    inicio_incendio TIMESTAMP,
    PRIMARY KEY (nro_brigada, nombre_bosque, inicio_incendio),
    FOREIGN KEY (nro_brigada) REFERENCES Bomberos(nro_brigada),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, inicio)
);

CREATE TABLE Recursos (
    nombre VARCHAR(100) PRIMARY KEY,
    tipo VARCHAR(100),
    descripcion TEXT
);

CREATE TABLE RecursosUtilizadosEnIncendio (
    nombre_recurso VARCHAR(100),
    nombre_bosque VARCHAR(100),
    inicio_incendio TIMESTAMP,
    cantidad INT,
    PRIMARY KEY (nombre_recurso, nombre_bosque, inicio_incendio),
    FOREIGN KEY (nombre_recurso) REFERENCES Recursos(nombre),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, inicio)
);

CREATE TABLE Tacticas (
    nombre VARCHAR(100) PRIMARY KEY,
    descripcion TEXT
);

CREATE TABLE TacticasUtilizadasEnIncendio (
    nombre_tactica VARCHAR(100),
    nombre_bosque VARCHAR(100),
    inicio_incendio TIMESTAMP,
    PRIMARY KEY (nombre_tactica, nombre_bosque, inicio_incendio),
    FOREIGN KEY (nombre_tactica) REFERENCES Tacticas(nombre),
    FOREIGN KEY (nombre_bosque, inicio_incendio) REFERENCES IncendiosForestales(nombre_bosque, inicio)
);
