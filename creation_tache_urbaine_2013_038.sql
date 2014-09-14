CREATE TABLE tu_2013_plus50_shp AS SELECT ST_Buffer(the_geom,50) AS the_geom FROM n_bati_dgi_038_2013; -- Buffer de 50m sur chaque objet de n_bati_dgi_038_2013

CREATE TABLE tu_2013_plus50_union_SHP AS SELECT ST_Union(the_geom) AS the_geom FROM tu_2013_plus50_shp; -- fusion des tampons en un seul objet

CREATE TABLE tu_2013_moins40_shp AS SELECT ST_Buffer(the_geom,-40) AS the_geom FROM tu_2013_plus50_union_SHP; -- Buffer de -40m sur chaque objet de tu_2013_plus50_union_SHP

CREATE TABLE l_tache_urbaine_2013_038 ( LIKE tu_2013_moins40_shp INCLUDING ALL );
INSERT INTO l_tache_urbaine_2013_038 SELECT (ST_Dump(the_geom)).geom as the_geom from tu_2013_moins40_shp;

ALTER TABLE l_tache_urbaine_2013_038
	ADD COLUMN som_dur integer,
	ADD COLUMN som_leger integer,
	ADD COLUMN temp_geom geometry(Polygon,2154);

UPDATE l_tache_urbaine_2013_038 SET som_dur = (SELECT count(*) FROM n_bati_dgi_038_2013 WHERE dur='Bati dur' and ST_Intersects(n_bati_dgi_038_2013.the_geom, l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nb_bati_dur
UPDATE l_tache_urbaine_2013_038 SET som_leger = (SELECT count(*) FROM n_bati_dgi_038_2013 WHERE dur='Bati leger' and ST_Intersects(n_bati_dgi_038_2013.the_geom, l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nb_bati_dur 
UPDATE l_tache_urbaine_2013_038 SET temp_geom = st_buffer(the_geom, 0.0); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nb_bati_dur 

ALTER TABLE l_tache_urbaine_2013_038 DROP COLUMN the_geom;
ALTER TABLE l_tache_urbaine_2013_038 RENAME COLUMN temp_geom TO the_geom;

CREATE INDEX l_tache_urbaine_2013_038_the_geom_gist ON l_tache_urbaine_2013_038 USING gist (the_geom);

SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM l_tache_urbaine_2013_038;