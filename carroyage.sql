-- USAGE : carroyage.sql -v zoom=<zoom> -v schema_cible=<schema_cible>
-- zoom : entier >= 1 
-- schema_cible : schema PostgreSQL pour l'ecriture de la table
--
-- vdct 2018
-- Licence : https://en.wikipedia.org/wiki/Beerware

\set zoomraster :zoom

SELECT (:zoom - 1) as zoomvecteur \gset
SELECT 'carroyage_raster_'||:zoomraster||'_vecteur_'||:zoomvecteur as tablename \gset

DROP TABLE IF EXISTS :schema_cible.:tablename CASCADE;
CREATE TABLE :schema_cible.:tablename (
    geometrie geometry (Polygon, 3857),
    x integer,
    y integer,
    z integer);

WITH s
AS
(SELECT generate_series(0,(2 ^ :zoom - 1)::integer) AS n),
matrice
AS
(SELECT step_x.n AS step_x,
        step_y.n AS step_y
 FROM   s AS step_x 
 CROSS JOIN s AS step_y),
coords
AS
(SELECT -20037508.34 + (40075016.68/(2 ^ :zoom)) *  step_x      AS xmin,
        -20037508.34 + (40075016.68/(2 ^ :zoom)) * (step_x + 1) AS xmax,
        -20037508.34 + (40075016.68/(2 ^ :zoom)) *  step_y      AS ymin,
        -20037508.34 + (40075016.68/(2 ^ :zoom)) * (step_y + 1) AS ymax,
        step_x,
        step_y
FROM    matrice)
INSERT INTO :schema_cible.:tablename
SELECT ST_SetSRID(ST_PolygonFromText('POLYGON (('||xmin||' '||ymin||','||xmin||' '||ymax||','||xmax||' '||ymax||','||xmax||' '||ymin||','||xmin||' '||ymin||'))'),3857),
       step_x,
       (2 ^ :zoom) - (step_y + 1),
       :zoom
FROM coords;

CREATE INDEX gidx_:tablename ON :schema_cible.:tablename USING GIST(geometrie);
