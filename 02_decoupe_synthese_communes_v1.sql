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
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbatidur = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE (dur='Bâti dur' OR dur='Bati dur') and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs [nbatidur]
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbatileg = (SELECT count(*) FROM cadastre_dgi.n_bati_dgi_038_2005 WHERE (dur='Bâti léger' OR dur='Bati leger') and ST_Intersects(cadastre_dgi.n_bati_dgi_038_2005.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom)); -- Compte le nombre de batiments en dur dans la tache urbaine et met la valeur dans le champs [nbatileg]
UPDATE foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038 SET nbagrege = (SELECT count(*) FROM foncier_sol__n_occupation_sol.l_bati_agrege_2005_038 WHERE ST_Intersects(foncier_sol__n_occupation_sol.l_bati_agrege_2005_038.the_geom, foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038.the_geom)); -- Compte le nombre de batiments de la couche des batiments agrégés compris dans la tache urbaine et met la valeur dans le champs [nbagrege]
---- Remarque : il y a des scories de taches urbaines qui ont le nombre de batiment à 0, cela est dû à la tache urbaine qui est découpée à la limite des communes mais dont les batiments sont sur la commune d'à coté.

---- Requête de synthèse du résultat de l'année
SELECT insee AS "INSEE",sum(ST_Area(the_geom)/10000) AS "SURFACE 2005 Ha"
FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038
WHERE annee = '2005'
GROUP BY insee
ORDER BY insee;

---- Requête de synthèse du résultat des communes
--SELECT insee AS "INSEE",annee AS "ANNEE", sum(ST_Area(the_geom)/10000) AS "SURFACE Ha"
--FROM foncier_sol__n_occupation_sol.l_toutes_taches_urbaines_038
--GROUP BY insee,annee
--ORDER BY insee,annee;