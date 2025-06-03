
DROP TABLE IF EXISTS infra_energia_por_muni; 
DROP TABLE IF EXISTS crecimiento_pob_vs_energia; 

-- 1. Infraestructuras nuevas desde 2014 hasta 2023
CREATE TEMP TABLE infra_energia_por_muni AS
SELECT municipio, provincia, COUNT(*) AS num_infra_nuevas
FROM btn_poi_energia
WHERE fecha >= '2015-01-01' AND fecha <= '2024-01-01'
GROUP BY municipio, provincia;

-- 2. Unir con variación poblacional
CREATE TABLE crecimiento_pob_vs_energia AS
SELECT v.nombre as municipio,
       v.provincia,
	   v.ccaa,
       v.pob_14_23 as var_pob_2014_2023,
       COALESCE(i.num_infra_nuevas, 0) AS num_infra_nuevas,
	   v.geom
FROM varpob2014_2023 v
LEFT JOIN infra_energia_por_muni i
  ON v.nombre = i.municipio AND v.provincia = i.provincia
ORDER BY num_infra_nuevas DESC;
