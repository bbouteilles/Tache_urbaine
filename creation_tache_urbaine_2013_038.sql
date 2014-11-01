--DROP TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038; --à utiliser pour débugage rapide
--DROP TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038; --à utiliser pour débugage rapide

------------------------------------------------
-- Partie Création de la table du bâti agrégé --
------------------------------------------------
CREATE TABLE tampon_bati_2013_plus1 AS SELECT ST_Buffer(the_geom,0,01) AS the_geom FROM cadastre_dgi.n_bati_dgi_038_2013; -- WHERE ogc_fid<11; --à utiliser pour débugage rapide -- Buffer de 1 cm sur chaque objet de n_bati_dgi_038_2013

CREATE TABLE fusion_tampon_bati_2013_plus1 AS SELECT ST_Union(the_geom) AS the_geom FROM tampon_bati_2013_plus1; -- Fusion des tampons en un seul objet

CREATE TABLE fusion_tampon_bati_2013 AS SELECT ST_Buffer(the_geom,-0,01) AS the_geom FROM fusion_tampon_bati_2013_plus1; -- Buffer de – 1 cm sur chaque objet de  fusion_tampon_bati_2013_plus1

--- Création de la table du bâti agrégé
CREATE TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038
(
  the_geom geometry(Polygon,2154)
);
INSERT INTO foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 SELECT (ST_Dump(the_geom)).geom as the_geom from fusion_tampon_bati_2013; --- Désagrégation des tampons fusionnés.

ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 -- ajout de deux colonnes supplémentaires pour renseigner le nombre de batiments qui ont été agrégés
	ADD COLUMN nbatidur integer,
	ADD COLUMN nbatileg integer;

UPDATE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2013 WHERE (dur='Bati dur' or dur='01') and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2013.the_geom, foncier_sol__n_occupation_sol.l_bati_agrege_2013_038.the_geom)); -- Compte le nombre de batiments en dur qui ont permis de générer ce batiment agrégé et met la valeur dans le champs  nbatidur
UPDATE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2013 WHERE (dur='Bati leger' or dur='02') and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2013.the_geom, foncier_sol__n_occupation_sol.l_bati_agrege_2013_038.the_geom)); -- Compte le nombre de batiments legers qui ont permis de générer ce batiment agrégé et met la valeur dans le champs nbatileg

-- Pour déplacer le champs géométrique à la fin
ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 ADD COLUMN temp_geom geometry(Polygon,2154);
UPDATE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 SET temp_geom = st_buffer(the_geom, 0.0);   
ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 DROP COLUMN the_geom;
ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 RENAME COLUMN temp_geom TO the_geom;

-- Index, contraintes et droits sur la base :
CREATE INDEX l_bati_agrege_2013_038_the_geom_gist ON foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 USING gist (the_geom); -- Index créé.
ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(the_geom) = 'POLYGON'::text OR the_geom IS NULL); --création à nouveau de la contrainte POLYGON
ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 ADD CONSTRAINT geometry_valid_check CHECK (ST_IsValid(the_geom));
-- contrainte de projection en 2154 ?

GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 TO postgres WITH GRANT OPTION;
--GRANT ALL ON SCHEMA foncier_sol__n_occupation_sol TO geobase38_administrateurs WITH GRANT OPTION; -- à mettre pour la géobase38
--GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2014_038 TO geobase38_consultation; -- à mettre pour la géobase38

-----------------------------------------------------
-- Partie Création de la table de la tache urbaine --
-----------------------------------------------------
CREATE TABLE tu_2013_plus50_038 AS SELECT ST_Buffer(the_geom,50) AS the_geom FROM foncier_sol__n_occupation_sol.l_bati_agrege_2013_038; -- Buffer de 50m sur chaque objet du foncier_sol__n_occupation_sol.l_bati_agrege_2013_038

CREATE TABLE tu_2013_plus50_union_038 AS SELECT ST_Union(the_geom) AS the_geom FROM tu_2013_plus50_038; -- fusion des tampons en un seul objet

CREATE TABLE tu_2013_moins40_038 AS SELECT ST_Buffer(the_geom,-40) AS the_geom FROM tu_2013_plus50_union_038; -- Buffer de -40m sur chaque objet de tu_2013_plus50_union_038

CREATE TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038
(
  the_geom geometry(Polygon,2154)
);
INSERT INTO foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 SELECT (ST_Dump(the_geom)).geom as the_geom from tu_2013_moins40_038; -- Désagrégation des tampons fusionnés.

ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 -- ajout de 3 colonnes supplémentaires pour renseigner le nombre de batiments qui ont été agrégés
	ADD COLUMN nbatidur integer,
	ADD COLUMN nbatileg integer,
	ADD COLUMN nbagrege integer;

UPDATE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2013 WHERE dur='Bati dur' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2013.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs  nbatidur
UPDATE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2013 WHERE dur='Bati leger' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2013.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nbatileg
UPDATE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 SET nbagrege = (SELECT count(*) FROM foncier_sol__n_occupation_sol.l_bati_agrege_2013_038 WHERE ST_Intersects(foncier_sol__n_occupation_sol.l_bati_agrege_2013_038.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038.the_geom)); -- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs  nbagrege

-- Pour déplacer le champs géométrique à la fin
ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 ADD COLUMN temp_geom geometry(Polygon,2154);
UPDATE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 SET temp_geom = st_buffer(the_geom, 0.0);
ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 DROP COLUMN the_geom;
ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 RENAME COLUMN temp_geom TO the_geom;

-- Index, contraintes et droits sur la base :
CREATE INDEX l_tache_urbaine_2013_038_the_geom_gist ON foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 USING gist (the_geom);
ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(the_geom) = 'POLYGON'::text OR the_geom IS NULL); --création à nouveau de la contrainte POLYGON
ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038 ADD CONSTRAINT geometry_valid_check CHECK (ST_IsValid(the_geom));
-- contrainte de projection en 2154 ?

----------------------------------------------------
-- Suppression des tables provisoires necessaires --
----------------------------------------------------
DROP TABLE tampon_bati_2013_plus1;
DROP TABLE fusion_tampon_bati_2013_plus1;
DROP TABLE fusion_tampon_bati_2013;
DROP TABLE tu_2013_plus50_038;
DROP TABLE tu_2013_plus50_union_038;
DROP TABLE tu_2013_moins40_038;

-------------------------
-- Requête de synthèse --
-------------------------
SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM foncier_sol__n_occupation_sol.l_tache_urbaine_2013_038;