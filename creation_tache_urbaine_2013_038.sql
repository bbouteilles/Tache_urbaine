CREATE TABLE tampon_bati_2013_plus1 AS SELECT ST_Buffer(the_geom,0,01) AS the_geom FROM cadastre_dgi.n_bati_dgi_038_2013; -- Buffer de 1 cm sur chaque objet de n_bati_dgi_038_2013

CREATE TABLE fusion_tampon_bati_2013_plus1 AS SELECT ST_Union(the_geom) AS the_geom FROM tampon_bati_2013_plus1; -- Fusion des tampons en un seul objet

CREATE TABLE fusion_tampon_bati_2013 AS SELECT ST_Buffer(the_geom,-0,01) AS the_geom FROM fusion_tampon_bati_2013_plus1; -- Buffer de – 1 cm sur chaque objet de  fusion_tampon_bati_2013_plus1

CREATE TABLE l_bati_agrege_2013_038 ( LIKE fusion_tampon_bati_2013 INCLUDING ALL );
INSERT INTO l_bati_agrege_2013_038 SELECT (ST_Dump(the_geom)).geom as the_geom from fusion_tampon_bati_2013; --- Création de la table du bati agrégé

CREATE TABLE tu_2013_plus50_038 AS SELECT ST_Buffer(the_geom,50) AS the_geom FROM l_bati_agrege_2013_038; -- Buffer de 50m sur chaque objet de fusion_tampon_bati_2013

CREATE TABLE tu_2013_plus50_union_038 AS SELECT ST_Union(the_geom) AS the_geom FROM tu_2013_plus50_038; -- fusion des tampons en un seul objet

CREATE TABLE tu_2013_moins40_038 AS SELECT ST_Buffer(the_geom,-40) AS the_geom FROM tu_2013_plus50_union_038; -- Buffer de -40m sur chaque objet de tu_2013_plus50_union_038

CREATE TABLE l_tache_urbaine_2013_038 ( LIKE tu_2013_moins40_038 INCLUDING ALL );
INSERT INTO l_tache_urbaine_2013_038 SELECT (ST_Dump(the_geom)).geom as the_geom from tu_2013_moins40_038;

ALTER TABLE l_tache_urbaine_2013_038
	ADD COLUMN nb_bati_dur integer,
	ADD COLUMN nb_bati_leger integer,
	ADD COLUMN nb_bati_agrege integer,
	ADD COLUMN temp_geom geometry(Polygon,2154);

UPDATE l_tache_urbaine_2013_038 SET nb_bati_dur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2013 WHERE dur='Bati dur' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2013.the_geom, l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nb_bati_dur
UPDATE l_tache_urbaine_2013_038 SET nb_bati_leger = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2013 WHERE dur='Bati leger' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2013.the_geom, l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nb_bati_dur

UPDATE l_tache_urbaine_2013_038 SET nb_bati_agrege = (SELECT count(*) FROM l_bati_agrege_2013_038 WHERE ST_Intersects(l_bati_agrege_2013_038.the_geom, l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs nb_bati_agrege

UPDATE l_tache_urbaine_2013_038 SET temp_geom = st_buffer(the_geom, 0.0); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs  

ALTER TABLE l_tache_urbaine_2013_038 DROP COLUMN the_geom;
ALTER TABLE l_tache_urbaine_2013_038 RENAME COLUMN temp_geom TO the_geom;

CREATE INDEX l_tache_urbaine_2013_038_the_geom_gist ON l_tache_urbaine_2013_038 USING gist (the_geom);

SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM l_tache_urbaine_2013_038;

--DROP TABLE tampon_bati_2013_plus1;
--DROP TABLE fusion_tampon_bati_2013;
--DROP TABLE fusion_tampon_bati_2013_plus1;
--DROP TABLE tu_2013_plus50_038;
--DROP TABLE tu_2013_plus50_union_038;
--DROP TABLE tu_2013_moins40_038;