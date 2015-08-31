----=============================================================================
---- GENERATION DU BATI AGREGE ET DE LA TACHE URBAINE A PARTIR DU CADASTRE DGFIP
---- Version 6 du 31/08/2015						Finalisé oui|x| / non | |
----=============================================================================
---- Rq : ---- pour les commentaires / -- pour les commandes optionnelles, debuger


---------------------------------------------------------------------------------------------------------------
---- Partie 1 : Génération du bâti agrégé pour d'autres applications (Application de la loi montagne notamment)
---------------------------------------------------------------------------------------------------------------

--DROP TABLE l_bati_agrege_2005_038;

CREATE TABLE l_bati_agrege_2005_038
(
  nbatidur integer,
  nbatileg integer,
  the_geom geometry(Polygon,2154)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE l_bati_agrege_2005_038
  OWNER TO postgres;

---- Buffer +0,01, ST_Union, Buffer -0,01, ST_Dump
INSERT INTO l_bati_agrege_2005_038 (the_geom) SELECT (ST_Dump(ST_Buffer(ST_Union(ST_Buffer(the_geom,0,01)),-0,01))).geom as the_geom from cadastre_dgi.n_bati_dgi_038_2005; --debug WHERE cadastre_dgi.n_bati_dgi_038_2005.codcomm = '38001';

---- Mise à jour des données attributaires
UPDATE l_bati_agrege_2005_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE dur='Bâti dur' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, l_bati_agrege_2005_038.the_geom)); -- Compte le nombre de batiments en dur qui ont permis de générer ce batiment agrégé et met la valeur dans le champs  nbatidur
UPDATE l_bati_agrege_2005_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE dur='Bâti léger' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, l_bati_agrege_2005_038.the_geom)); -- Compte le nombre de batiments legers qui ont permis de générer ce batiment agrégé et met la valeur dans le champs nbatileg

----Index géométrique
CREATE INDEX l_bati_agrege_2005_038_the_geom_gist ON l_bati_agrege_2005_038 USING gist (the_geom);

---- Rq de Synthèse à mettre en place pour vérifier le résultat
--Debug SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM l_bati_agrege_2005_038;


-----------------------------------------------
---- Partie 2 : Génération de la tache urbaine
-----------------------------------------------
--Debug : DROP TABLE l_tache_urbaine_2005_038;

CREATE TABLE l_tache_urbaine_2005_038
(
  nbatidur integer,
  nbatileg integer,
  nbagrege integer,
  the_geom geometry(Polygon,2154)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE l_tache_urbaine_2005_038
  OWNER TO postgres;

---- Buffer +50, ST_Union, Buffer -40, ST_Dump
INSERT INTO l_tache_urbaine_2005_038 (the_geom) SELECT (ST_Dump(ST_Buffer(ST_Union(ST_Buffer(the_geom,50)),-40))).geom as the_geom from cadastre_dgi.n_bati_dgi_038_2005; --debug WHERE cadastre_dgi.n_bati_dgi_038_2005.codcomm = '38001';

---- Mise à jour des données attributaires
UPDATE l_tache_urbaine_2005_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE dur='Bâti dur' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, l_tache_urbaine_2005_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs  nbatidur
UPDATE l_tache_urbaine_2005_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE dur='Bâti léger' and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, l_tache_urbaine_2005_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs nbatileg
UPDATE l_tache_urbaine_2005_038 SET nbagrege = (SELECT count(*) FROM l_bati_agrege_2005_038 WHERE ST_Intersects(l_bati_agrege_2005_038.the_geom, l_tache_urbaine_2005_038.the_geom)); -- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs  nbagrege

----Index géométrique
CREATE INDEX l_tache_urbaine_2005_038_the_geom_gist ON l_tache_urbaine_2005_038 USING gist (the_geom);

---- Rq de Synthèse
--Debug SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM l_tache_urbaine_2005_038;


-------------------------------------------------------------------------
---- Partie 3 : Intégration définitive dans la Géobase38 avec les Droits
-------------------------------------------------------------------------

----Déplace la table dans le bon schéma de la Géobase
ALTER TABLE l_bati_agrege_2005_038 SET SCHEMA foncier_sol__n_occupation_sol;
ALTER TABLE l_tache_urbaine_2005_038 SET SCHEMA foncier_sol__n_occupation_sol;

----Changement de propriétaire
ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2005_038
	OWNER TO gb_adm;
ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038
	OWNER TO gb_adm;

----Attribution des droits géobase38 pour les administrateur
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2005_038 TO geobase38_administrateurs;
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038 TO geobase38_administrateurs;

----Attribution des droits géobase38 pour la Production
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2005_038 TO geobase38_production;
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038 TO geobase38_production;

----Attribution des droits géobase38 pour la Consultation
GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2005_038 TO public.geobase38_consultation;
GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038 TO public.geobase38_consultation;