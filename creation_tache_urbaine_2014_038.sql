-------------------------------------------------------------------------------------------------------------
-- Partie 1 : Génération du bâti agrégé pour d'autres applications (Application de la loi montagne notamment)
-------------------------------------------------------------------------------------------------------------
-- Debug : DROP TABLE l_bati_agrege_2014_038;

CREATE TABLE l_bati_agrege_2014_038
(
  nbatidur integer,
  nbatileg integer,
  the_geom geometry(Polygon,2154)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE l_bati_agrege_2014_038
  OWNER TO postgres;

-- Buffer +0,01, ST_Union, Buffer -0,01, ST_Dump
INSERT INTO l_bati_agrege_2014_038 (the_geom) SELECT (ST_Dump(ST_Buffer(ST_Union(ST_Buffer(the_geom,0,01)),-0,01))).geom as the_geom from cadastre_dgi.n_bati_dgi_038_2014; --debug : WHERE cadastre_dgi.n_bati_dgi_038_2014.codcomm = '38001';

-- Mise à jour des données attributaires
UPDATE l_bati_agrege_2014_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2014 WHERE dur='Bâti dur' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2014.the_geom, l_bati_agrege_2014_038.the_geom)); -- Compte le nombre de batiments en dur qui ont permis de générer ce batiment agrégé et met la valeur dans le champs  nbatidur
UPDATE l_bati_agrege_2014_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2014 WHERE dur='Bâti léger' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2014.the_geom, l_bati_agrege_2014_038.the_geom)); -- Compte le nombre de batiments legers qui ont permis de générer ce batiment agrégé et met la valeur dans le champs nbatileg

--Index géométrique
CREATE INDEX l_bati_agrege_2014_038_the_geom_gist ON l_bati_agrege_2014_038 USING gist (the_geom);

--------------------------------------------
-- Partie 2 : Génération de la tache urbaine
--------------------------------------------
-- Debug : DROP TABLE l_tache_urbaine_2014_038;

CREATE TABLE l_tache_urbaine_2014_038
(
  nbatidur integer,
  nbatileg integer,
  nbagrege integer,
  the_geom geometry(Polygon,2154)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE l_tache_urbaine_2014_038
  OWNER TO postgres;

  -- Buffer +50, ST_Union, Buffer -40, ST_Dump
INSERT INTO l_tache_urbaine_2014_038 (the_geom) SELECT (ST_Dump(ST_Buffer(ST_Union(ST_Buffer(the_geom,50)),-40))).geom as the_geom from cadastre_dgi.n_bati_dgi_038_2014; --debug : WHERE cadastre_dgi.n_bati_dgi_038_2014.codcomm = '38001';

-- Mise à jour des données attributaires
UPDATE l_tache_urbaine_2014_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2014 WHERE dur='Bâti dur' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2014.the_geom, l_tache_urbaine_2014_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs  nbatidur
UPDATE l_tache_urbaine_2014_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2014 WHERE dur='Bâti léger' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2014.the_geom, l_tache_urbaine_2014_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nbatileg
UPDATE l_tache_urbaine_2014_038 SET nbagrege = (SELECT count(*) FROM l_bati_agrege_2014_038 WHERE ST_Intersects(l_bati_agrege_2014_038.the_geom, l_tache_urbaine_2014_038.the_geom)); -- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs  nbagrege

--Index géométrique
CREATE INDEX l_tache_urbaine_2014_038_the_geom_gist ON l_tache_urbaine_2014_038 USING gist (the_geom);

-- Rq de Synthèse
SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM l_tache_urbaine_2014_038;