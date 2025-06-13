= Implémentation d'une mémoire

== Choix de la mémoire
Selon les spécifications du projet, la mémoire doit pouvoir stocker 12 fenêtres de 57 échantillons chacune pour les valeurs de référence. Chaque échantillon étant codé sur 16 bits, cela représente un total de 12 × 57 × 16 = 11'664 bits, soit 1'458 octets. Pour la mémoire dédiée aux fenêtres d’analyse, une taille d’environ 4'096 octets avait été prévue, permettant de traiter jusqu’à 35 fenêtres simultanément. Afin de garantir une marge de sécurité et de flexibilité, une mémoire totale de 8'192 octets a finalement été implémentée.

== Implémentation de la mémoire
La mémoire a été implémentée à l’aide d’un bloc RAM _dual-port_ dans Quartus. Ce choix permet des accès simultanés et indépendants depuis deux ports, ce qui répond parfaitement à notre besoin : le processeur HPS peut lire les données pendant que le FPGA les écrit, sans conflit.

La structure de la mémoire, conforme aux spécifications, est illustrée ci-dessous :
#figure(image("../media/memoire.png"), caption: [Paramètre de la mémoire interne])

La mémoire comporte 2048 adresses de 4 octets chacune, offrant une capacité totale de 8192 octets. Chaque adresse est accessible à la fois par le HPS et le FPGA, assurant ainsi une gestion efficace et flexible des échanges de données entre les deux entités.

== Problèmes rencontrés
Lors de l’implémentation, nous avons rencontré des difficultés liées à la synchronisation entre le HPS et le FPGA, notamment lors des accès concurrents à la mémoire. Ces problèmes ont entraîné des incohérences dans les données échangées et complexifié la gestion des accès simultanés. Par manque de temps pour approfondir le débogage et mettre en place des mécanismes de synchronisation robustes, nous n’avons pas pu finaliser l’intégration complète de la mémoire dans le système.

== Leçons apprises
Cette expérience, comme pour la partie avec le DMA, nous a souligné l’importance cruciale d’une planification rigoureuse et d’une validation systématique des composants avant leur implémentation. Une phase de simulation approfondie, menée en amont, nous aurait permis de développer et de tester la mémoire de façon indépendante, en identifiant plus tôt les risques liés aux accès concurrents et aux problèmes de synchronisation. Cela aurait facilité l’intégration finale et renforcé la fiabilité du système.

