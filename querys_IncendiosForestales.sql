--Listar incendios de un bosque
select ts_inicio, ts_fin, estacion, hect_quemadas, latitud_inicio, longitud_inicio
from incendiosforestales
where nombre_bosque = 'Bosque El Silencio';


--Ranking incendios más destructivos (más hectáreas quemadas)
SELECT nombre_bosque, ts_inicio, hect_quemadas, 
	RANK () OVER (ORDER BY hect_quemadas DESC) as destruccion
FROM incendiosforestales
ORDER BY destruccion;


--Ranking incendios más destructivos por bosque 
SELECT nombre_bosque, ts_inicio, hect_quemadas,
  RANK() OVER (PARTITION BY nombre_bosque ORDER BY hect_quemadas DESC) AS ranking_incendio
FROM incendiosforestales;


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


--Hectáreas quemadas por año
SELECT 
  DATE_PART('year', ts_inicio) AS año,
  SUM(hect_quemadas) AS total_hectareas_quemadas
FROM IncendiosForestales
GROUP BY año
ORDER BY año;


--Promedio bomberos en cada incendio
SELECT AVG(b.cantidad_bomberos)
FROM bomberos b INNER JOIN bomberosenincendios bi ON (b.nro_brigada = bi.nro_brigada);


--Cantidad de incendios de cada tipo de causa
SELECT c.tipo, COUNT(ci.inicio_incendio) AS cantidad_incendios
FROM causasincendios ci INNER JOIN causas c ON (ci.nombre_causa = c.nombre)
GROUP BY c.tipo;


--Cantidad de incendios por causa
SELECT nombre_causa, COUNT(*) AS cantidad_incendios
FROM CausasIncendios
GROUP BY nombre_causa
ORDER BY cantidad_incendios DESC;


--Cantidad de turistas en un bosque los 5 días previos a un incendio
SELECT 
  i.nombre_bosque,
  i.ts_inicio,
  SUM(a.cant_turistas) AS total_turistas_5dias_previos
FROM IncendiosForestales i
JOIN AfluenciasTuristicas a
  ON i.nombre_bosque = a.nombre_bosque
  AND a.fecha BETWEEN (i.ts_inicio::date - INTERVAL '5 days') 
                  AND (i.ts_inicio::date - INTERVAL '1 day')
GROUP BY i.nombre_bosque, i.ts_inicio
ORDER BY i.ts_inicio;


--Cantidad de recurso utilizado en incendios ocurridos en verano
SELECT i.nombre_bosque, ru.nombre_recurso, count(ru.nombre_recurso)
FROM recursosutilizadosenincendios ru INNER JOIN incendiosforestales i ON (ru.nombre_bosque = i.nombre_bosque and ru.inicio_incendio = i.ts_inicio)
WHERE i.estacion = 'verano'
GROUP BY i.nombre_bosque, ru.nombre_recurso;


--Indice savi por bosque promedio luego de incendios
SELECT i.nombre_bosque, AVG(idxs.valor_savi)
FROM indicessavi idxs INNER JOIN incendiosforestales i ON (idxs.nombre_bosque = i.nombre_bosque)
		INNER JOIN incendiosforestales i2 ON (idxs.nombre_bosque = i2.nombre_bosque)
WHERE i.ts_fin < i2.ts_inicio and idxs.fecha > i.ts_fin and idxs.fecha < i2.ts_inicio
GROUP BY i.nombre_bosque;

--Indice GLI antes y después de un incendio
SELECT
  i.nombre_bosque,
  i.ts_inicio,
  i.ts_fin,
  gli_antes.valor_gli AS gli_antes,
  gli_despues.valor_gli AS gli_despues
FROM IncendiosForestales i
LEFT JOIN LATERAL (
  SELECT valor_gli
  FROM IndicesGLI
  WHERE nombre_bosque = i.nombre_bosque
    AND fecha <= i.ts_inicio::date
  ORDER BY fecha DESC
  LIMIT 1
) AS gli_antes ON true
LEFT JOIN LATERAL (
  SELECT valor_gli
  FROM IndicesGLI
  WHERE nombre_bosque = i.nombre_bosque
    AND fecha >= i.ts_fin::date
  ORDER BY fecha ASC
  LIMIT 1
) AS gli_despues ON true;


--Incendios con más superficie quemada que el mayor incendio del bosque nro 2 en ranking de superficie total quemada
WITH bosque_mas_afectado as (
	SELECT i.nombre_bosque
	FROM incendiosforestales i
	GROUP BY i.nombre_bosque
	ORDER BY SUM(i.hect_quemadas) DESC
	OFFSET 1 ROWS FETCH FIRST 1 ROWS ONLY
)
SELECT nombre_bosque, ts_inicio, hect_quemadas
FROM incendiosforestales
WHERE hect_quemadas > ALL (
	SELECT hect_quemadas
	FROM incendiosforestales
	WHERE nombre_bosque = (SELECT nombre_bosque FROM bosque_mas_afectado)
);


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