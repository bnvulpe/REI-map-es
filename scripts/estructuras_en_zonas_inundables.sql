-- Crear vista de ríos largos
CREATE OR REPLACE VIEW rios_largos AS
SELECT *
FROM rios
WHERE long_cauce > 100;

-- Crear buffer (100 m) en torno a esos ríos
CREATE OR REPLACE VIEW buffer_rios_largos AS
SELECT ST_Buffer(geom::geography, 100)::geometry AS geom
FROM rios_largos;

-- Ver qué instalaciones están dentro del buffer y no son centrales hidráulicas
DROP TABLE IF EXISTS instalaciones_en_riesgo_inundacion;

CREATE TABLE instalaciones_en_riesgo_inundacion AS
SELECT e.*
FROM btn_poi_energia e
JOIN buffer_rios_largos b
  ON ST_Intersects(e.geom, b.geom)
WHERE LOWER(clase_new) NOT LIKE '%hidráulica%';
