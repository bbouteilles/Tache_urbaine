----=============================================================================
---- 	DECOUPE COMMUNALE DE LA TACHE URBAINE ET STATISTIQUES D'EVOLUTION
---- 	Version 1 du 31/08/2015						Finalisé oui| | / non |X|
----=============================================================================
---- Rq : ---- pour les commentaires / -- pour les commandes optionnelles, debuger
---- Rq : configurée pour l'année 2005

---------------------------------------------------------------------------
---- Partie 1 : Découpe à la commune : référence : n_commune_geofla_038_2005
---------------------------------------------------------------------------

----Si la base de synthèse n'a pas encore créée :
--DROP TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038;
CREATE TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038
(
  insee char(5),
  annee char(4),
  nbatidur integer,
  nbatileg integer,
  nbagrege integer,
  the_geom geometry(Polygon,2154)
 
)
WITH (
  OIDS=TRUE
);
ALTER TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038
  OWNER TO postgres;

------------------------------------------------------------------------------------------------------------------------  
----Attribution des droits Géobase38 pour les administrateur
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 TO geobase38_administrateurs;
GRANT ALL ON TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 TO geobase38_administrateurs;

----Attribution des droits Géobase38 pour la Production
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.l_bati_agrege_2005_038 TO geobase38_production;
--GRANT SELECT,INSERT,DELETE ON TABLE foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038 TO geobase38_production;

----Attribution des droits Géobase38 pour la Consultation
GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 TO public.geobase38_consultation;
GRANT SELECT ON TABLE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 TO public.geobase38_consultation;
------------------------------------------------------------------------------------------------------------------------

---- Requète qui éclate la tache urbaine selon le perimètre des communes:
---- Optimisation du temps de la requête récupéré sur cette page : http://postgis.refractions.net/docs/ST_Intersection.html
INSERT INTO foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 (insee,annee,the_geom)
	SELECT
		n_commune_geofla_038_2005.insee_com,
		'2005',
		 (ST_Dump(ST_Multi(ST_Buffer(
				ST_Intersection(n_commune_geofla_038_2005.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038.the_geom),
				0.0)
				))).geom AS the_geom
	FROM n_commune_geofla_038_2005
		INNER JOIN foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038
			ON ST_Intersects(n_commune_geofla_038_2005.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038.the_geom)
		WHERE Not ST_IsEmpty(ST_Buffer(ST_Intersection(n_commune_geofla_038_2005.the_geom, foncier_sol__n_occupation_sol.l_tache_urbaine_2005_038.the_geom),0.0));
--débug			AND (n_commune_geofla_038_2005.insee_com = '38001' or n_commune_geofla_038_2005.insee_com = '38165');  -- Deux communes voisines pour vérifier la découpe

---- Ajout des valeurs de bati :
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE (dur='Bâti dur' OR dur='Bati dur') AND ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom) AND annee='2005'); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs [nbatidur]
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE (dur='Bâti léger' OR dur='Bati leger') AND ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom) AND annee='2005'); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs [nbatileg]
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbagrege = (SELECT count(*) FROM foncier_sol__n_occupation_sol.l_bati_agrege_2005_038 WHERE ST_Intersects(foncier_sol__n_occupation_sol.l_bati_agrege_2005_038.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom) AND annee='2005'); -- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs [nbagrege]
---- Remarque : il y a des scories de taches urbaines qui ont le nombre de batiment à 0, cela est dû à la tache urbaine qui est découpée à la limite des communes mais dont les batiments sont sur la commune d'à coté.

---- Requête de synthèse du résultat de l'année
SELECT insee AS "INSEE",sum(ST_Area(the_geom)/10000) AS "SURFACE 2005 Ha"
FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038
WHERE annee = '2005'
GROUP BY insee
ORDER BY insee;


---------------------------------------------------------------------------
---- Partie 2 : Vue de synthèse des taches urbaines commune par commune
---- pour une table qui contient les années 2005 à 2015
---------------------------------------------------------------------------
----
-- View: foncier_sol__n_occupation_sol.v_taches_urbaines_communes_038

--DROP VIEW foncier_sol__n_occupation_sol.v_taches_urbaines_communes_038;

CREATE OR REPLACE VIEW foncier_sol__n_occupation_sol.v_taches_urbaines_communes_038 AS 
 SELECT r1.insee AS "INSEE",
    ( SELECT sum(st_area(t5.the_geom)) AS "surf_2005"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t5
          WHERE t5.annee = '2005'::bpchar AND t5.insee = r1.insee
          GROUP BY t5.insee) AS "surf_2005",
    ( SELECT sum(st_area(t6.the_geom)) AS "surf_2006"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t6
          WHERE t6.annee = '2006'::bpchar AND t6.insee = r1.insee
          GROUP BY t6.insee) AS "surf_2006",
    ( SELECT sum(st_area(t7.the_geom)) AS "surf_2007"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t7
          WHERE t7.annee = '2007'::bpchar AND t7.insee = r1.insee
          GROUP BY t7.insee) AS "surf_2007",
    ( SELECT sum(st_area(t8.the_geom)) AS "surf_2008"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t8
          WHERE t8.annee = '2008'::bpchar AND t8.insee = r1.insee
          GROUP BY t8.insee) AS "surf_2008",
    ( SELECT sum(st_area(t9.the_geom)) AS "surf_2009"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t9
          WHERE t9.annee = '2009'::bpchar AND t9.insee = r1.insee
          GROUP BY t9.insee) AS "surf_2009",
    ( SELECT sum(st_area(t10.the_geom)) AS "surf_2010"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t10
          WHERE t10.annee = '2010'::bpchar AND t10.insee = r1.insee
          GROUP BY t10.insee) AS "surf_2010",
    ( SELECT sum(st_area(t11.the_geom)) AS "surf_2011"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t11
          WHERE t11.annee = '2011'::bpchar AND t11.insee = r1.insee
          GROUP BY t11.insee) AS "surf_2011",
    ( SELECT sum(st_area(t12.the_geom)) AS "surf_2012"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t12
          WHERE t12.annee = '2012'::bpchar AND t12.insee = r1.insee
          GROUP BY t12.insee) AS "surf_2012",
    ( SELECT sum(st_area(t13.the_geom)) AS "surf_2013"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t13
          WHERE t13.annee = '2013'::bpchar AND t13.insee = r1.insee
          GROUP BY t13.insee) AS "surf_2013",
    ( SELECT sum(st_area(t14.the_geom)) AS "surf_2014"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t14
          WHERE t14.annee = '2014'::bpchar AND t14.insee = r1.insee
          GROUP BY t14.insee) AS "surf_2014",
    ( SELECT sum(st_area(t15.the_geom)) AS "suf_2015"
           FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 t15
          WHERE t15.annee = '2015'::bpchar AND t15.insee = r1.insee
          GROUP BY t15.insee) AS "surf_2015"
   FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 r1
  GROUP BY r1.insee
  ORDER BY r1.insee;