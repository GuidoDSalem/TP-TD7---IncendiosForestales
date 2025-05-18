--Ranking incendios más destructivos
SELECT nombre_bosque, ts_inicio, RANK () OVER (ORDER BY hect_quemadas) as destruccion,
FROM incendiosforestales,
ORDER BY destruccion DESC;

--Tácticas utilizadas en un incendio de más de 15 hectáreas
SELECT t.nombre, i.nombre_bosque, i.ts_inicio
FROM tacticas t INNER JOIN tacticasutilizadasenincendios ti ON (t.nombre = ti.nombre_tactica)
	INNER JOIN incendiosforestales i ON (ti.nombre_bosque = i.nombre_bosque and ti.inicio_incendio=i.ts_inicio )
WHERE i.hect_quemadas>15;

--Superficie quemada en cada bosque teniendo en cuenta todos sus incendios
SELECT i.nombre_bosque, SUM(i.hect_quemadas) as total_quemado
FROM incendiosforestales i
GROUP BY i.nombre_bosque
ORDER BY total_quemado DESC;

--Promedio bomberos usados en cada incendio

--Clasificación de incendios según su intensidad potencial
WITH estadisticasfuego AS (
  SELECT MIN(longitud_llamas) AS min_long, MAX(longitud_llamas) AS max_long,
    MIN(altura_llamas) AS min_alt, MAX(altura_llamas) AS max_alt,
    MIN(humedad_comb_FFMC) AS min_hum_FFMC, MAX(humedad_comb_FFMC) AS max_hum_FFMC,
    MIN (humedad_comb_DMC) AS min_hum_DMC, MAX(humedad_comb_DMC) AS max_hum_DMC,
    MIN (humedad_comb_DC) AS min_hum_DC, MAX(humedad_comb_DC) AS max_hum_DC
  FROM comportamientosincendios
),
normalizacion as (
	SELECT i.nombre_bosque, i.ts_inicio, i.hect_quemadas,
       (c.longitud_llamas-ef.min_long)/(ef.max_long-ef.min_long) as long_normaliz,
	   (c.altura_llamas-ef.min_alt)/(ef.max_alt-ef.min_alt) as alt_normaliz,
	   (c.humedad_comb_FFMC-ef.min_hum_FFMC)/(ef.max_hum_FFMC-ef.min_hum_FFMC) as FFMC_normaliz,
	   (c.humedad_comb_DMC-ef.min_hum_DMC)/(ef.max_hum_DMC-ef.min_hum_DMC) as DMC_normaliz,
  	   (c.humedad_comb_DC-ef.min_hum_DC)/(ef.max_hum_DC-ef.min_hum_DC) as DC_normaliz   
	FROM comportamientosincendios c INNER JOIN incendiosforestales i ON (i.nombre_bosque = c.nombre_bosque AND i.ts_inicio = c.inicio_incendio), estadisticasfuego ef
)
SELECT nombre_bosque, ts_inicio, hect_quemadas,
  	CASE
        WHEN (long_normaliz + alt_normaliz) - ((FFMC_normaliz+DMC_normaliz+DC_normaliz)/3) >= 0.3 THEN 'Alta'
        WHEN (long_normaliz + alt_normaliz) - ((FFMC_normaliz+DMC_normaliz+DC_normaliz)/3) >= 0.15 THEN 'Media'
        ELSE 'Baja'
    END AS riesgo_intensidad 
FROM normalizacion;