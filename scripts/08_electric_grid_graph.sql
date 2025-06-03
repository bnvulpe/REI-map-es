-- Crear red base 
DROP TABLE IF EXISTS red_grafo;
CREATE TABLE red_grafo AS
SELECT 
  row_number() OVER () AS gid,
  ST_SetSRID((ST_Dump(geom)).geom, 25830)::geometry(LINESTRING, 25830) AS geom,
  ST_Length((ST_Dump(geom)).geom::geography) AS cost
FROM btn100_0702l_lin_elec
WHERE geom IS NOT NULL;

ALTER TABLE red_grafo
ADD COLUMN source integer,
ADD COLUMN target integer;

-- Crear topología
SELECT pgr_createTopology(
 'red_grafo',    
 0.001,                
 the_geom:='geom',
 id:='gid', 
 source:='source', target:='target');

-- Cambiar el SRID de la geometría a 4258 (ETRS89) y crear un índice espacial

ALTER TABLE red_grafo
ALTER COLUMN geom TYPE geometry(LineString, 4258)
USING ST_SetSRID(geom, 4258);

CREATE INDEX IF NOT EXISTS idx_red_geom ON red_grafo USING GIST (geom);

-- 4. Tabla de nodos
DROP TABLE IF EXISTS red_nodos;
CREATE TABLE red_nodos AS
SELECT id, ST_Union(geom) AS geom
FROM (
  SELECT source AS id, ST_StartPoint(geom) AS geom FROM red_grafo
  UNION ALL
  SELECT target AS id, ST_EndPoint(geom) AS geom FROM red_grafo
) AS nodos
GROUP BY id;

-- Transformaciones
SELECT * FROM red_nodos;

CREATE INDEX red_nodos_geom_idx
ON red_nodos
USING GIST (geom);

-- Asociar subestaciones a nodos ('btn_poi_energia' con clase_new = 'Otro')
DROP TABLE IF EXISTS nodos_subestacion;
CREATE TABLE nodos_subestacion AS
SELECT DISTINCT n.id
FROM red_nodos n
JOIN btn_poi_energia p
  ON ST_DWithin(n.geom, p.geom, 0.009) -- ≈ 1 km
WHERE p.clase_new = 'Otro';

--- Tabla para visualizar en QGIS, separado en caso de realizar cambios 
DROP TABLE IF EXISTS nodos_subestacion_visual;
CREATE TABLE nodos_subestacion_visual AS
SELECT DISTINCT n.id, n.geom
FROM red_nodos n
JOIN btn_poi_energia p
  ON ST_DWithin(n.geom, p.geom, 0.009) -- ≈ 1 km
WHERE p.clase_new = 'Otro';
----------------------------------------------------------------------------------------------------------------------------------
-- Extras que no se han incluido en el análisis, pero que pueden ser útiles para visualización o análisis posterior
-- Identificar qué nodos están conectados a municipios y provincias. Usar centroides de municipios para emparejar al nodo más cercano
CREATE INDEX IF NOT EXISTS denspob2023_geom_idx ON denspob2023 USING GIST (geom); 

DROP TABLE IF EXISTS nodo_municipio;

CREATE TABLE nodo_municipio AS
SELECT 
    m.gid AS municipio_id, 
    m.nombre AS municipio,
	m.provincia,
    n.id AS nodo_id
FROM denspob2023 m
JOIN red_nodos n
  ON ST_Contains(m.geom, n.geom)
WHERE m.geom && n.geom;
-- Seleccionamos nodos que estén en provincia 
DROP TABLE IF EXISTS nodos_provincia; 
CREATE TEMP TABLE nodos_provincia AS
SELECT nodo_id
FROM nodo_municipio
WHERE provincia = 'Sevilla';

SELECT * FROM nodos_provincia;

-- Vemos las líneas que tienen esos nodos 
DROP TABLE IF EXISTS aristas_sevilla;
CREATE  TABLE aristas_sevilla AS
SELECT *
FROM red_grafo
WHERE source IN (SELECT nodo_id FROM nodos_provincia)
   OR target IN (SELECT nodo_id FROM nodos_provincia);

SELECT * FROM aristas_sevilla;

-- Simular eliminación de la líneas
DROP TABLE IF EXISTS red_grafo_fallo_sevilla;

CREATE TABLE red_grafo_fallo_sevilla AS
SELECT g.*
FROM red_grafo g
WHERE NOT EXISTS (
    SELECT 1
    FROM aristas_sevilla a
    WHERE a.gid = g.gid
);
----------------------------------------------------------------------------------------------------------------------------------
-- Recalcular la conectividad usando pgRouting, te da una lista de municipios que quedan aislados si se eliminan las línea.
DROP TABLE IF EXISTS municipios_sin_conex;

CREATE  TABLE municipios_sin_conex AS
SELECT DISTINCT nm.municipio_id AS nodo_id, d.geom
FROM nodo_municipio nm
LEFT JOIN LATERAL (
  SELECT * FROM pgr_dijkstra(
    'SELECT gid AS id, source, target, cost FROM red_grafo',
    nm.nodo_id,
    ARRAY(SELECT id FROM nodos_subestacion),
    directed := false
  )
) AS ruta ON true
JOIN denspob2023 d ON d.gid = nm.municipio_id
WHERE ruta.node IS NULL;

-- Detectar componentes biconectados, y luego identificar las aristas que están en un único componente (potenciales puentes).
-- Si un arista está sola en un componente → probablemente sea una arista de corte. 
CREATE TEMP TABLE connected_comp AS 
SELECT * FROM pgr_biconnectedComponents(
  'SELECT gid AS id,cost, source, target FROM red_grafo'
);

CREATE TEMP TABLE potential_bridges AS 
SELECT edge
FROM connected_comp
WHERE component IN (
  SELECT component
  FROM connected_comp
  GROUP BY component
  HAVING COUNT(*) = 1
);

SELECT * FROM red_grafo
WHERE gid not in (Select edge from potential_bridges);

-- Eliminar aristas puente 

DROP TABLE IF EXISTS red_grafo_no_bridges;

CREATE TABLE red_grafo_no_bridges AS
SELECT 
    g.*, 
    cc.component
FROM red_grafo g
JOIN connected_comp cc ON g.gid = cc.edge
WHERE NOT EXISTS (
    SELECT 1
    FROM potential_bridges a
    WHERE a.edge = g.gid
);

