-- Crear índices en capas iniciales
CREATE INDEX IF NOT EXISTS idx_denspob_geom ON denspob2023 USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_pob_geom ON pob USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_proyectos_geom ON proyectos_sing USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_poi_geom ON btn_poi_energia USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_red_geom ON btn100_0702l_lin_elec USING GIST (geom);

-- Municipios con baja densidad
DROP TABLE IF EXISTS tmp_municipios_baja_densidad;
CREATE TEMP TABLE tmp_municipios_baja_densidad AS
SELECT *
FROM denspob2023
WHERE dens_pob < 50;

-- Crear la tabla vacía para rellenar poblaciones de cada municipio de baja densidad
ALTER TABLE pob
ADD COLUMN id_unico SERIAL PRIMARY KEY;

DROP TABLE IF EXISTS tmp_pob_baja_densidad;
CREATE TABLE tmp_pob_baja_densidad AS
SELECT * FROM pob WHERE false;

ALTER TABLE tmp_pob_baja_densidad
ADD COLUMN nombre_municipio text;

-- Rellenar 
INSERT INTO tmp_pob_baja_densidad (
    gid, id, idpob, fecha, cpro, ine, geom, codine, nombre, tipo, id_unico, nombre_municipio
)
SELECT 
    p.gid, p.id, p.idpob, p.fecha, p.cpro, p.ine, p.geom, p.codine, p.nombre, p.tipo, p.id_unico,
    m.nombre AS nombre_municipio
FROM pob p
JOIN tmp_municipios_baja_densidad m
  ON ST_Within(p.geom, ST_Transform(m.geom, 25830))
ORDER BY p.id_unico
OFFSET 0 LIMIT 1000;

-- Excluir núcleos con proyectos activos de categoría rural
DROP TABLE IF EXISTS tmp_pob_sin_proyectos;
CREATE TEMP TABLE tmp_pob_sin_proyectos AS
SELECT p.*
FROM tmp_pob_baja_densidad p
WHERE NOT EXISTS (
    SELECT 1
    FROM proyectos_sing ps
    WHERE ST_Intersects(p.geom, ST_Transform(ps.geom, 25830))
      AND ps.categoría IN (
        'Innovación y digitalización rural', 
        'Dinamización y desarrollo rural'
      )
);

-- Excluir núcleos cercanos a POIs de energía (radio 12 km)
-- Crear buffer de 12km de puntos poi
CREATE TEMP TABLE poi_buffer AS
SELECT ST_Buffer(ST_Transform(geom, 25830), 12000) AS geom
FROM btn_poi_energia;

--  Unificar buffer
CREATE TEMP TABLE poi_union AS
SELECT ST_Union(geom) AS geom
FROM poi_buffer;

-- Crear tabla de puntos fuera del área de influencia energética
DROP TABLE IF EXISTS tmp_pob_sin_poi;
CREATE TEMP TABLE tmp_pob_sin_poi AS
SELECT p.*
FROM tmp_pob_sin_proyectos p
WHERE NOT ST_Within(p.geom, (SELECT geom FROM poi_union));

-- Calcular distancia a línea eléctrica más cercana (solo si están dentro de 20 km)
CREATE INDEX IF NOT EXISTS idx_tmp_pob_geom ON tmp_pob_sin_poi USING GIST (geom);

DROP TABLE IF EXISTS p_batch;
CREATE TEMP TABLE p_batch AS
SELECT 
    *, 
    ST_Transform(geom, 4326)::geography AS geog
FROM tmp_pob_sin_poi
ORDER BY id_unico;

CREATE INDEX ON p_batch USING GIST (geog);

DROP TABLE IF EXISTS r_geog;
CREATE TEMP TABLE r_geog AS
SELECT  *, ST_Transform(geom, 4326)::geography AS geog
FROM btn100_0702l_lin_elec;

CREATE INDEX ON r_geog USING GIST (geom);

-- Creamos tabla final con las distancias 
DROP TABLE IF EXISTS zonas_criticas_electrificacion;

CREATE TABLE zonas_criticas_electrificacion AS
SELECT 
    p.*, 
    NULL::double precision AS distancia_m_linea_electrica
FROM p_batch p
WHERE false;

-- Rellenamos las distancias si son menores a 20km
INSERT INTO zonas_criticas_electrificacion
SELECT 
    p.*,
	
    (
        SELECT MIN(ST_Distance(p.geog, r.geog))
        FROM r_geog r
        WHERE ST_DWithin(p.geog, r.geog, 20000)
    ) AS distancia_m_linea_electrica
FROM p_batch p
ORDER BY p.id_unico; 

SELECT distancia_m_linea_electrica FROM zonas_criticas_electrificacion;

-- Cambiamos valores de null a numérico
UPDATE zonas_criticas_electrificacion
SET distancia_m_linea_electrica = 99999
WHERE distancia_m_linea_electrica IS NULL;

-- Añadir provincia y ccaa a la tabla
SELECT id_unico, nombre, nombre_municipio,distancia_m_linea_electrica, ccaa, provincia  FROM zonas_criticas_electrificacion;
SELECT * FROM denspob2023;

ALTER TABLE zonas_criticas_electrificacion 
ADD COLUMN ccaa TEXT,
ADD COLUMN provincia TEXT;

UPDATE zonas_criticas_electrificacion z
SET 
    ccaa = d.ccaa,
    provincia = d.provincia
FROM 
    denspob2023 d
WHERE 
    z.nombre_municipio = d.nombre;

