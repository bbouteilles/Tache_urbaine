----=============================================================================
---- AJOUT DE L'ANNNEE 2015 SUR UNE GEOBASE EXISTANTE
---- Version 1 du 24/10/2015						Finalisée oui| | / non |X|
----=============================================================================
---- Rq : ---- pour les commentaires / -- pour les commandes optionnelles, debuger


--------------------------------------------------------------------------------------------------------------------
---- Partie 1 : Génération du bâti agrégé 2015 pour d'autres applications (Application de la loi montagne notamment)
--------------------------------------------------------------------------------------------------------------------

--DROP TABLE l_bati_agrege_2015_038;

CREATE TABLE l_bati_agrege_2015_038
(
  nbatidur integer,
  nbatileg integer,
  the_geom geometry(Polygon,2154)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE l_bati_agrege_2015_038
  OWNER TO postgres;

---- Buffer +0,01, ST_Union, Buffer -0,01, ST_Dump
INSERT INTO l_bati_agrege_2015_038 (the_geom)
	SELECT (ST_Dump(ST_Buffer(ST_Union(ST_Buffer(the_geom,0,01)),-0,01))).geom AS the_geom
	FROM cadastre__dgi.n_bati_dgi_038_2015;
--debug WHERE cadastre_dgi.n_bati_dgi_038_2015.codcomm = '38001';
----> La requête a été exécutée avec succés : 440414 lignes modifiées. La requête a été exécutée en 6730677 ms.

----Index géographique sur la table pour accélerer les requêtes qui vont suivre
CREATE INDEX l_bati_agrege_2015_038_the_geom_gist ON l_bati_agrege_2015_038 USING gist (the_geom);

---- Mise à jour du cahmps nbatidur dans les données attributaires
---- Compte le nombre de batiments en dur qui ont permis de générer ce batiment agrégé et met la valeur dans le champs nbatidur
UPDATE l_bati_agrege_2015_038 SET nbatidur = (
	SELECT count(*)
	FROM cadastre__dgi.n_bati_dgi_038_2015
	WHERE (dur='Bâti dur' or dur='Bati dur' or dur='01')
		AND ST_Intersects(cadastre__dgi.n_bati_dgi_038_2015.the_geom, l_bati_agrege_2015_038.the_geom)
);
---->La requête a été exécutée avec succés : 440414 lignes modifiées. La requête a été exécutée en 169752 ms.

---- Compte le nombre de batiments legers qui ont permis de générer ce batiment agrégé et met la valeur dans le champs nbatileg
UPDATE l_bati_agrege_2015_038 SET nbatileg = (
	SELECT count(*)
	FROM cadastre__dgi.n_bati_dgi_038_2015
	WHERE (dur='Bâti léger' or dur='Bati leger' or dur='02')
		AND ST_Intersects(cadastre__dgi.n_bati_dgi_038_2015.the_geom, l_bati_agrege_2015_038.the_geom)
);
---->La requête a été exécutée avec succés : 440414 lignes modifiées. La requête a été exécutée en 63695 ms.

----Optimisation Extrême : réorganise les pages de la table afin que les objets géographiquement proches les uns des autres
----le soit aussi dans les pages dans la base.
CLUSTER l_bati_agrege_2015_038 USING l_bati_agrege_2015_038_the_geom_gist;

---- Rq de Synthèse à mettre en place pour vérifier le résultat
--Debug SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM l_bati_agrege_2015_038;


--------------------------------------------------
---- Partie 2 : Génération de l'envloppe urbaine
--------------------------------------------------
--Debug : DROP TABLE l_tache_urbaine_2015_038;

CREATE TABLE l_tache_urbaine_2015_038
(
  nbatidur integer,
  nbatileg integer,
  nbagrege integer,
  the_geom geometry(Polygon,2154)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE l_tache_urbaine_2015_038
  OWNER TO postgres;

---- Buffer +50, ST_Union, Buffer -40, ST_Dump
INSERT INTO l_tache_urbaine_2015_038 (the_geom)
	SELECT (ST_Dump(ST_Buffer(ST_Union(ST_Buffer(the_geom,50)),-40))).geom AS the_geom
	FROM cadastre__dgi.n_bati_dgi_038_2015;
--debug WHERE cadastre_dgi.n_bati_dgi_038_2015.codcomm = '38001';
---->La requête a été exécutée avec succés : 23252 lignes modifiées. La requête a été exécutée en 1367282 ms.

----Index géométrique sur la table pour accélerer les requêtes qui vont suivre
CREATE INDEX l_tache_urbaine_2015_038_the_geom_gist ON l_tache_urbaine_2015_038 USING gist (the_geom);

---- Mise à jour des données attributaires
---- Compte le nombre de batiments en dur qui ont permis de générer cette envloppe urbaine et met la valeur dans le champs nbatidur
UPDATE l_tache_urbaine_2015_038 SET nbatidur = (
	SELECT count(*)
	FROM cadastre__dgi.n_bati_dgi_038_2015
	WHERE (dur='Bâti dur' or dur='Bati dur' or dur='01') and ST_Intersects(cadastre__dgi.n_bati_dgi_038_2015.the_geom, l_tache_urbaine_2015_038.the_geom)
);

---- Compte le nombre de batiments légers qui ont permis de générer cette envloppe urbaine et met la valeur dans le champs nbatileg
UPDATE l_tache_urbaine_2015_038 SET nbatileg = (
	SELECT count(*)
	FROM cadastre__dgi.n_bati_dgi_038_2015
	WHERE (dur='Bâti léger' or dur='Bati leger' or dur='02') and ST_Intersects(cadastre__dgi.n_bati_dgi_038_2015.the_geom, l_tache_urbaine_2015_038.the_geom)
);

---- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs  nbagrege
UPDATE l_tache_urbaine_2015_038 SET nbagrege = (
	SELECT count(*)
	FROM l_bati_agrege_2015_038
	WHERE ST_Intersects(l_bati_agrege_2015_038.the_geom, l_tache_urbaine_2015_038.the_geom)
);

----Optimisation Extrême : réorganise les pages de la table afin que les objets géographiquement proches les uns des autres
----le soit aussi dans les pages dans la base.
CLUSTER l_tache_urbaine_2015_038 USING l_tache_urbaine_2015_038_the_geom_gist;

---- Rq de Synthèse
--Debug SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface FROM l_tache_urbaine_2015_038;


-------------------------------------------------------------------------
---- Partie 3 : Intégration définitive dans la Géobase38 avec les Droits
-------------------------------------------------------------------------

----Déplace la table dans le bon schéma de la Géobase
ALTER TABLE l_bati_agrege_2015_038 SET SCHEMA foncier_sol__n_occupation_sol;
ALTER TABLE l_tache_urbaine_2015_038 SET SCHEMA foncier_sol__n_occupation_sol;

----Changement de propriétaire
ALTER TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2015_038
	OWNER TO gb_adm;
ALTER TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038
	OWNER TO gb_adm;

----Attribution des droits géobase38 pour les administrateur
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2015_038 TO geobase38_administrateurs;
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038 TO geobase38_administrateurs;

----Attribution des droits géobase38 pour la Production
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2015_038 TO geobase38_production;
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038 TO geobase38_production;

GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2015_038 TO public.geobase38_consultation;
GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038 TO public.geobase38_consultation;


----------------------------------------------------------------------------------------
---- Partie 4 : Découpe à la commune depuis la référence : public.n_commune_bdt_038_2015
----------------------------------------------------------------------------------------

---- Suppression des index pour augmenter la vitesse de la requête :
DROP INDEX foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038_the_geom_gist;
DROP INDEX foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038_insee_btree;
DROP INDEX foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038_annee_btree;

---- Requête qui éclate la tache urbaine selon le perimètre des communes:
---- Optimisation du temps de la requête récupéré sur cette page : http://postgis.refractions.net/docs/ST_Intersection.html
INSERT INTO foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 (insee,annee,the_geom)
	SELECT
		n_commune_bdt_038_2015.code_insee,
		'2015',
		 (ST_Dump(ST_Multi(ST_Buffer(
				ST_Intersection(n_commune_bdt_038_2015.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038.the_geom),
				0.0)
				))).geom AS the_geom
	FROM n_commune_bdt_038_2015
		INNER JOIN foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038
			ON ST_Intersects(n_commune_bdt_038_2015.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038.the_geom)
		WHERE Not ST_IsEmpty(ST_Buffer(ST_Intersection(n_commune_bdt_038_2015.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2015_038.the_geom),0.0));
--debug			AND (n_commune_bdt_038_2015.code_insee = '38001' or n_commune_bdt_038_2015.code_insee = '38165');  -- Deux communes voisines pour vérifier la découpe
----> La requête a été exécutée avec succés : 25440 lignes modifiées. La requête a été exécutée en 109264 ms.

---- Rq de Synthèse
--Debug SELECT count(*) AS nb_objets, sum(ST_Area(the_geom)) AS surface
--	FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038
--	WHERE l_toutes_taches_urbaines_038.annee = '2015';
----> 25440;576606362.868591

----Index géométrique sur la table pour accélerer les requêtes qui vont suivre
CREATE INDEX l_toutes_taches_urbaines_038_the_geom_gist ON foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 USING gist (the_geom);

---- Ajout des valeurs de bati pour 2015 :
---- Compte le nombre de batiments en dur dans la tache urbaine fr 2015 et met la valeur dans le champs [nbatidur]
---- Remarque : il y a des scories de taches urbaines qui ont le nombre de batiment à 0, cela est dû à la tache urbaine qui est découpée à la limite des communes mais dont les batiments sont sur la commune d'à coté.
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbatidur = (
	SELECT count(*)
	FROM cadastre__dgi.n_bati_dgi_038_2015
	WHERE (dur='Bâti dur' OR dur='Bati dur') AND ST_Intersects(cadastre__dgi.n_bati_dgi_038_2015.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom) AND annee='2015');
----> La requête a été exécutée avec succés : 238877 lignes modifiées. La requête a été exécutée en 76487 ms.

---- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs [nbatileg]
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbatileg = (
	SELECT count(*)
	FROM cadastre__dgi.n_bati_dgi_038_2015
	WHERE (dur='Bâti léger' OR dur='Bati leger') AND ST_Intersects(cadastre__dgi.n_bati_dgi_038_2015.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom) AND annee='2015');
----> La requête a été exécutée avec succés : 238877 lignes modifiées. La requête a été exécutée en 59717 ms.

---- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs [nbagrege]
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbagrege = (
	SELECT count(*)
	FROM foncier_sol__n_occupation_sol.l_bati_agrege_2015_038
	WHERE ST_Intersects(foncier_sol__n_occupation_sol.l_bati_agrege_2015_038.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom) AND annee='2015');
----> La requête a été exécutée avec succés : 238877 lignes modifiées. La requête a été exécutée en 68437 ms.

---- Rajout des index
CREATE INDEX l_toutes_taches_urbaines_038_insee_idx ON foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 USING btree (insee COLLATE pg_catalog."default");
CREATE INDEX l_toutes_taches_urbaines_038_annee_idx ON foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 USING btree (annee COLLATE pg_catalog."default");

----Optimisation Extrême : réorganise les pages de la table afin que les objets géographiquement proches les uns des autres
----le soit aussi dans les pages dans la base.
CLUSTER foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 USING l_toutes_taches_urbaines_038_the_geom_gist;


------------------------------------------------------------------------------------------------
---- Partie 5 : Ajout de 2015 dans la table de synthèse des taches urbaines commune par commune
------------------------------------------------------------------------------------------------

DROP TABLE foncier_sol__n_occupation_sol.t_tu_synthese_038;

CREATE TABLE foncier_sol__n_occupation_sol.t_tu_synthese_038 AS 
 SELECT r1.insee AS insee,
    ( SELECT sum(st_area(t5.the_geom)) AS "surf_2005"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t5
          WHERE t5.annee = '2005'::bpchar AND t5.insee = r1.insee
          GROUP BY t5.insee) AS "surf_2005",
    ( SELECT sum(st_area(t6.the_geom)) AS "surf_2006"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t6
          WHERE t6.annee = '2006'::bpchar AND t6.insee = r1.insee
          GROUP BY t6.insee) AS "surf_2006",
    ( SELECT sum(st_area(t7.the_geom)) AS "surf_2007"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t7
          WHERE t7.annee = '2007'::bpchar AND t7.insee = r1.insee
          GROUP BY t7.insee) AS "surf_2007",
    ( SELECT sum(st_area(t8.the_geom)) AS "surf_2008"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t8
          WHERE t8.annee = '2008'::bpchar AND t8.insee = r1.insee
          GROUP BY t8.insee) AS "surf_2008",
    ( SELECT sum(st_area(t9.the_geom)) AS "surf_2009"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t9
          WHERE t9.annee = '2009'::bpchar AND t9.insee = r1.insee
          GROUP BY t9.insee) AS "surf_2009",
    ( SELECT sum(st_area(t10.the_geom)) AS "surf_2010"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t10
          WHERE t10.annee = '2010'::bpchar AND t10.insee = r1.insee
          GROUP BY t10.insee) AS "surf_2010",
    ( SELECT sum(st_area(t11.the_geom)) AS "surf_2011"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t11
          WHERE t11.annee = '2011'::bpchar AND t11.insee = r1.insee
          GROUP BY t11.insee) AS "surf_2011",
    ( SELECT sum(st_area(t12.the_geom)) AS "surf_2012"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t12
          WHERE t12.annee = '2012'::bpchar AND t12.insee = r1.insee
          GROUP BY t12.insee) AS "surf_2012",
    ( SELECT sum(st_area(t13.the_geom)) AS "surf_2013"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t13
          WHERE t13.annee = '2013'::bpchar AND t13.insee = r1.insee
          GROUP BY t13.insee) AS "surf_2013",
    ( SELECT sum(st_area(t14.the_geom)) AS "surf_2014"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t14
          WHERE t14.annee = '2014'::bpchar AND t14.insee = r1.insee
          GROUP BY t14.insee) AS "surf_2014",
    ( SELECT sum(st_area(t15.the_geom)) AS "suf_2015"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS t15
          WHERE t15.annee = '2015'::bpchar AND t15.insee = r1.insee
          GROUP BY t15.insee) AS "surf_2015"
  FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 AS r1, n_commune_bdt_038_2015 AS r2
  WHERE r1.insee=r2.code_insee
  GROUP BY r1.insee
  ORDER BY r1.insee;

---- Ajout index sur insee  
CREATE INDEX t_tu_synthese_038_insee_btree
  ON foncier_sol__n_occupation_sol.t_tu_synthese_038
  USING btree
  (insee);
  
---- Ajout des champs statistiques
ALTER TABLE foncier_sol__n_occupation_sol.t_tu_synthese_038
	ADD COLUMN diff_2006_2005 double precision,
	ADD COLUMN evol_2006_2005 double precision,
	ADD COLUMN diff_2007_2006 double precision,
	ADD COLUMN evol_2007_2006 double precision,
	ADD COLUMN diff_2008_2007 double precision,
	ADD COLUMN evol_2008_2007 double precision,
	ADD COLUMN diff_2009_2008 double precision,
	ADD COLUMN evol_2009_2008 double precision,
	ADD COLUMN diff_2010_2009 double precision,
	ADD COLUMN evol_2010_2009 double precision,
	ADD COLUMN diff_2011_2010 double precision,
	ADD COLUMN evol_2011_2010 double precision,
	ADD COLUMN diff_2012_2011 double precision,
	ADD COLUMN evol_2012_2011 double precision,
	ADD COLUMN diff_2013_2012 double precision,
	ADD COLUMN evol_2013_2012 double precision,
	ADD COLUMN diff_2014_2013 double precision,
	ADD COLUMN evol_2014_2013 double precision,
	ADD COLUMN diff_2015_2014 double precision,
	ADD COLUMN evol_2015_2014 double precision;

---- Calcul des différences et des pourcentages d'évolutions
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2006_2005 = surf_2006-surf_2005;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2006_2005 = (surf_2006-surf_2005)/surf_2005*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2007_2006 = surf_2007-surf_2006;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2007_2006 = (surf_2007-surf_2006)/surf_2006*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2008_2007 = surf_2008-surf_2007;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2008_2007 = (surf_2008-surf_2007)/surf_2007*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2009_2008 = surf_2009-surf_2008;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2009_2008 = (surf_2009-surf_2008)/surf_2008*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2010_2009 = surf_2010-surf_2009;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2010_2009 = (surf_2010-surf_2009)/surf_2009*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2011_2010 = surf_2011-surf_2010;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2011_2010 = (surf_2011-surf_2010)/surf_2010*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2012_2011 = surf_2012-surf_2011;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2012_2011 = (surf_2012-surf_2011)/surf_2011*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2013_2012 = surf_2013-surf_2012;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2013_2012 = (surf_2013-surf_2012)/surf_2012*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2014_2013 = surf_2014-surf_2013;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2014_2013 = (surf_2014-surf_2013)/surf_2013*100;

UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET diff_2015_2014 = surf_2015-surf_2014;
UPDATE foncier_sol__n_occupation_sol.t_tu_synthese_038 SET evol_2015_2014 = (surf_2015-surf_2014)/surf_2014*100;

----Attribution des droits géobase38 pour les administrateur
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 TO geobase38_administrateurs;
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.t_tu_synthese_038 TO geobase38_administrateurs;

----Attribution des droits géobase38 pour la Production
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 TO geobase38_production;
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.t_tu_synthese_038 TO geobase38_production;

GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 TO public.geobase38_consultation;
GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.t_tu_synthese_038 TO public.geobase38_consultation;