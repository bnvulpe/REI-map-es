-- 1. Crear buffer de 500 m alrededor de infraestructuras energéticas
DROP VIEW IF EXISTS buffer_energia_500m CASCADE;

CREATE VIEW buffer_energia_500m AS
SELECT ST_Buffer(geom::geography, 500)::geometry AS geom
FROM btn_poi_energia;

-- 2. Ríos libres de presión energética
DROP TABLE IF EXISTS rios_libres_presion;

CREATE TABLE rios_libres_presion AS
SELECT r.*
FROM rios r
WHERE NOT EXISTS (
  SELECT 1
  FROM buffer_energia_500m b
  WHERE ST_Intersects(r.geom, b.geom)
);

-- 3. Masas de agua libres de presión energética
DROP TABLE IF EXISTS masas_agua_libres_presion;

CREATE TABLE masas_agua_libres_presion AS
SELECT m.*
FROM masas_agua m
WHERE NOT EXISTS (
  SELECT 1
  FROM buffer_energia_500m b
  WHERE ST_Intersects(m.geom, b.geom)
);

-- 4. Conectividad río–masa (ríos a menos de 100 m de una masa de agua)
DROP TABLE IF EXISTS conectividad_rio_masa_libres;

CREATE TABLE conectividad_rio_masa_libres AS
SELECT
  r.nom_cauce,
  m.nombremasa,
  ST_Union(r.geom, m.geom) AS corredor_geom
FROM rios_libres_presion r
JOIN masas_agua_libres_presion m
  ON ST_DWithin(r.geom, m.geom, 100);

-- 5. (Opcional) Añadir longitud del corredor
ALTER TABLE conectividad_rio_masa_libres ADD COLUMN longitud_km DOUBLE PRECISION;

UPDATE conectividad_rio_masa_libres
SET longitud_km = ST_Length(corredor_geom::geography) / 1000.0;
