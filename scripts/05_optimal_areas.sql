-- 0. Limpiar temporales previas si existen
DROP TABLE IF EXISTS zonas_optimas_renovables;

DROP TABLE IF EXISTS enp_buffer;
DROP TABLE IF EXISTS red_buffer;
DROP TABLE IF EXISTS enp_union;
DROP TABLE IF EXISTS red_union;

-- 1. Crear buffer de 1km de espacios naturales protegidos
CREATE TEMP TABLE enp_buffer AS
SELECT ST_Buffer(ST_Transform(geom, 25830), 1000) AS geom
FROM enp2023;

-- 3. Crear buffer de 12km de red eléctrica
CREATE TEMP TABLE red_buffer AS
SELECT ST_Buffer(ST_Transform(geom, 25830), 12000) AS geom
FROM btn100_0702l_lin_elec;

-- 4. Unificar buffer eléctrico
CREATE TEMP TABLE red_union AS
SELECT ST_Union(geom) AS geom
FROM red_buffer;

-- 2. Unificar buffer enp en un solo polígono para eficiencia
CREATE TEMP TABLE enp_union AS
SELECT ST_Union(geom) AS geom
FROM enp_buffer;

SELECT * FROM enp_union;
SELECT * FROM red_union;

-- 5. Crear la tabla final con zonas óptimas
CREATE TABLE zonas_optimas_renovables AS
SELECT 
    d.nombre,
    d.ccaa,
    d.provincia,
    d.dens_pob,
    ST_Intersection(
        ST_Difference(ST_Transform(d.geom, 25830), enp.geom),
        red.geom
    ) AS geom
FROM denspob2023 d
CROSS JOIN enp_union enp
CROSS JOIN red_union red
WHERE d.dens_pob < 50;

-- 6. Alterar geometrías y configuración para la visualización en QGIS
ALTER TABLE zonas_optimas_renovables
ALTER COLUMN geom TYPE geometry(MultiPolygon, 25830)
USING ST_Multi(ST_SetSRID(geom, 25830));

CREATE INDEX zonas_optimas_renovables_geom_idx
ON zonas_optimas_renovables
USING GIST (geom);

SELECT *
FROM zonas_optimas_renovables;

--- 7. Crear la tabla final con zonas óptimas para Energía Térmica (densidad media-alta en lugar de baja)
CREATE TABLE zonas_optimas_renovables_termica AS
SELECT 
    d.nombre,
    d.ccaa,
    d.provincia,
    d.dens_pob,
    ST_Intersection(
        ST_Difference(ST_Transform(d.geom, 25830), enp.geom),
        red.geom
    ) AS geom
FROM denspob2023 d
CROSS JOIN enp_union enp
CROSS JOIN red_union red
WHERE d.dens_pob > 100;

-- 8. Alterar geometrías y configuración para la visualización en QGIS
ALTER TABLE zonas_optimas_renovables_termica
ALTER COLUMN geom TYPE geometry(MultiPolygon, 25830)
USING ST_Multi(ST_SetSRID(geom, 25830));

CREATE INDEX zonas_optimas_renovables_termica_geom_idx
ON zonas_optimas_renovables_termica
USING GIST (geom);

-- 9. Crear buffer de 1km de rios y masas de agua 
CREATE TEMP TABLE rio_buffer AS
SELECT ST_Buffer(ST_Transform(geom, 25830), 1000) AS geom
FROM rios;

CREATE TEMP TABLE masas_agua_buffer AS
SELECT ST_Buffer(ST_Transform(geom, 25830), 1000) AS geom
FROM masas_agua;

-- 10. Unificar buffers
CREATE TEMP TABLE union_buffers AS
SELECT ST_Union(geom) AS geom
FROM (
  SELECT geom FROM rio_buffer
  UNION ALL
  SELECT geom FROM masas_agua_buffer
) AS all_buffers;

-- 11. Interseccion entre hidrografia y zonas_optimas para Energía Hidráulica 
CREATE TABLE zonas_optimas_renovables_hidra AS
SELECT 
	z.nombre,
    z.ccaa,
    z.provincia,
    z.dens_pob,
    ST_Intersection(z.geom, b.geom) AS geom
FROM zonas_optimas_renovables z
JOIN union_buffers b
  ON ST_Intersects(z.geom, b.geom);

-- 12. Alterar geometrías y configuración para la visualización en QGIS
ALTER TABLE zonas_optimas_renovables_hidra
ALTER COLUMN geom TYPE geometry(MultiPolygon, 25830)
USING ST_Multi(ST_SetSRID(geom, 25830));

CREATE INDEX zonas_optimas_renovables_hidra_geom_idx
ON zonas_optimas_renovables_hidra
USING GIST (geom);

-- 13. Eliminar municipios en los que haya puntos poi del tipo de energía indicado
-- Eólica
DROP TABLE IF EXISTS zonas_optimas_eolica_sin_proyectos;
CREATE TABLE zonas_optimas_eolica_sin_proyectos AS
SELECT z.*
FROM zonas_optimas_renovables z
WHERE NOT EXISTS (
    SELECT 1
    FROM btn_poi_energia btn
    WHERE ST_Intersects(z.geom, ST_Transform(btn.geom, 25830))
      AND btn.clase_new = 'Parque eólico'
);
-- Solar
DROP TABLE IF EXISTS zonas_optimas_solar_sin_proyectos;
CREATE TABLE zonas_optimas_solar_sin_proyectos AS
SELECT z.*
FROM zonas_optimas_renovables z
WHERE NOT EXISTS (
    SELECT 1
    FROM btn_poi_energia btn
    WHERE ST_Intersects(z.geom, ST_Transform(btn.geom, 25830))
      AND btn.clase_new = 'Central solar'
);
-- Hidráulica
DROP TABLE IF EXISTS zonas_optimas_hidra_sin_proyectos;
CREATE TABLE zonas_optimas_hidra_sin_proyectos AS
SELECT z.*
FROM zonas_optimas_renovables_hidra z
WHERE NOT EXISTS (
    SELECT 1
    FROM btn_poi_energia btn
    WHERE ST_Intersects(z.geom, ST_Transform(btn.geom, 25830))
      AND btn.clase_new = 'Central hidráulica'
);
