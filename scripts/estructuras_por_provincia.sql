DROP TABLE IF EXISTS evolucion_energia_provincia;

CREATE TABLE evolucion_energia_provincia AS
SELECT
  provincia,
  clase_new,
  EXTRACT(YEAR FROM fecha::date)::int AS anio,
  COUNT(*) AS total
FROM btn_poi_energia
GROUP BY provincia, clase_new, anio
ORDER BY provincia, anio, clase_new;
