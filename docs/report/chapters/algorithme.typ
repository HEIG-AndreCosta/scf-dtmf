
= Algorithme

== Principe de fonctionnement
L'algorithme implémenté repose sur un principe de corrélation avec des fenêtres de référence pré-calculées.
Lorsqu'une pression de touche est détectée, le système calcule le produit scalaire entre la fenêtre audio captée et chacune des fenêtres de
référence correspondant aux différentes touches DTMF. La fenêtre de référence produisant le plus grand produit scalaire détermine la touche pressée.

== Stratégie de parcours temporel

Une fois le système aligné avec la première fenêtre, l'algorithme effectue des sauts temporels optimisés selon deux scénarios :

Saut de 0.25 secondes après détection d'une touche : Cette durée correspond aux 0.2 secondes de pression garanties plus un minimum de 0.05 secondes de silence
Saut de 0.15 secondes après détection d'un silence : Ce délai permet de se positionner au moment de la prochaine pression

Cette stratégie exploite intelligemment les contraintes temporelles imposées pour minimiser le nombre de calculs tout en garantissant la
détection de toutes les pressions.

== Détection de silence

La distinction entre signal utile et silence s'effectue par comparaison d'amplitude. Une fenêtre est considérée comme du silence si son
amplitude ne dépasse pas 90% de l'amplitude de référence mesurée au début du fichier (lors de la calibration initiale).

== Dimensionnement des fenêtres

Les fenêtres d'analyse ont une taille de 57 échantillons, calculée selon la formule :

$ N_"samples" = 5 * ((8000 "Hz") / (697 "Hz")) = 57 $

Cette dimension correspond à 5 fois le nombre minimal d'échantillons nécessaires pour analyser la fréquence la plus basse du système DTMF (697 Hz).
Le facteur 5 est un choix arbitraire qui améliore la précision de l'analyse tout en respectant le critère de Nyquist (facteur minimum de 2).

== Phases de traitement

L'algorithme se décompose en trois phases distinctes :

- Phase d'extraction : Parcours unique du buffer audio pour identifier et extraire toutes les fenêtres d'intérêt
- Phase de corrélation : Calcul du produit scalaire entre chaque fenêtre extraite et les 12 fenêtres de référence DTMF
- Phase de reconstruction : Génération de la séquence finale en analysant la fréquence d'apparition de chaque touche détectée

La phase de corrélation, étant très facilement parallèlisable, est une opération parfaite à effectuer au niveau hardware.
