Tache_urbaine
=============

Génération de la tache urbaine sur le département de l'Isère en PostgreSQL/Postgis à partir de la couche du bâti du cadastre de la DDFiP : n_bati_dgi_038_20xx

1°) Pour le bâti : génération de la couche : l_bati_agrege_20xx_038
- on agrandit le bâti via un buffer de + 1cm,
- on agrège les buffers qui se supperposent,
- on enlève de nouveau les 1 cm via un buffer de - 1cm,
- on desagrège l'ensemble des polygones de la couche.
- on ajoute les champs [nbatidur] et [nbatileg] et on compte le nombre de batiments du cadastre DDFiP avec la valeur dur ='Bati dur' et dur ='Bati leger' qui ont générés ce batiment agrégé.

2°) A partir de ce bati agrégé : génération de la couche : l_tache_urbaine_20xx_038
- on agrandit le bati agrégé via un buffer de + 50 m,
- on agrège les buffers (bati éloigné de moins de 100 m),
- on enlève de nouveau 40 cm via un buffer de - 40 m,
- on desagrège l'ensemble des polygones de la couche.
- on ajoute les champs [nbatidur] et [nbatileg] et [nbagrege] on compte le nombre de batiments du cadastre DDFiP avec la valeur dur ='Bati dur' et dur ='Bati leger' et de batiments agrégés qui ont générés cette tache urbaine.

L'ensemble du résultat est versé via GéoRhôneAlpes : http://www.georhonealpes.fr
