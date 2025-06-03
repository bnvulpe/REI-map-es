-- 1. Crear tabla de emisiones acumuladas por instalación
CREATE OR REPLACE VIEW instalaciones_gei_emisiones AS
SELECT
  *,
  (
    COALESCE(CAST(CASE WHEN f2005::text ~ '^[0-9\.]+$' THEN f2005 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2006::text ~ '^[0-9\.]+$' THEN f2006 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2007::text ~ '^[0-9\.]+$' THEN f2007 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2008::text ~ '^[0-9\.]+$' THEN f2008 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2009::text ~ '^[0-9\.]+$' THEN f2009 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2010::text ~ '^[0-9\.]+$' THEN f2010 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2011::text ~ '^[0-9\.]+$' THEN f2011 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2012::text ~ '^[0-9\.]+$' THEN f2012 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2013::text ~ '^[0-9\.]+$' THEN f2013 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2014::text ~ '^[0-9\.]+$' THEN f2014 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2015::text ~ '^[0-9\.]+$' THEN f2015 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2016::text ~ '^[0-9\.]+$' THEN f2016 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2017::text ~ '^[0-9\.]+$' THEN f2017 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2018::text ~ '^[0-9\.]+$' THEN f2018 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2019::text ~ '^[0-9\.]+$' THEN f2019 ELSE NULL END AS double precision), 0) +
    COALESCE(CAST(CASE WHEN f2020::text ~ '^[0-9\.]+$' THEN f2020 ELSE NULL END AS double precision), 0)
  ) AS total_emisiones
FROM instalacionescde;



-- 2. Crear buffer de 1 km alrededor de cada instalación
DROP VIEW IF EXISTS buffer_gei CASCADE;

CREATE OR REPLACE VIEW buffer_gei AS
SELECT
  gid,
  total_emisiones,
  ST_Buffer(geom::geography, 1000)::geometry AS geom
FROM instalaciones_gei_emisiones;


-- 3. Zonas residenciales dentro del buffer
DROP TABLE IF EXISTS zonas_pobladas_expuestas_gei;

CREATE TABLE zonas_pobladas_expuestas_gei AS
SELECT
  d.*,
  b.gid AS id_instalacion,
  b.total_emisiones
FROM denspob2023 d
JOIN buffer_gei b
  ON ST_Intersects(d.geom, b.geom);

-- 4. Espacios naturales protegidos dentro del buffer
DROP TABLE IF EXISTS espacios_protegidos_expuestos_gei;

CREATE TABLE espacios_protegidos_expuestos_gei AS
SELECT
  e.*,
  b.gid AS id_instalacion,
  b.total_emisiones
FROM enp2023 e
JOIN buffer_gei b
  ON ST_Intersects(e.geom, b.geom);
