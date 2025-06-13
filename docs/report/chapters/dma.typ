= Problèmes rencontrés avec le DMA

== Dysfonctionnements critiques

L'implémentation du design initial s'est heurtée à des problèmes majeurs lors de l'utilisation du bloc MSGDMA d'Altera.
Chaque tentative de transfert DMA provoquait un crash complet de la carte DE1-SoC, rendant le système totalement inutilisable.

== Analyse avec Signal Tap

L'utilisation de Signal Tap Logic Analyzer nous a permis d'identifier précisément le point de défaillance du système.
Les observations révèlent une séquence d'événements systématique :

- Phase de configuration : Les quatre écritures de configuration au contrôleur DMA s'effectuent correctement 
  (adresse de lecture, adresse d'écriture, taille du transfert et commande de démarrage)
- Initiation du transfert : Le bloc DMA initie correctement un accès en lecture vers la SDRAM
- Crash système : Immédiatement après le premier accès mémoire, la carte devient complètement non-responsive


#figure(image("../media/msgdma_crash.png"), caption: [Configuration MSGDMA suivi de crash])

== Isolement du problème

Pour vérifier que le dysfonctionnement ne provenait pas de notre IP custom, nous avons configuré le bloc MSGDMA en mode "loopback",
avec les ports de lecture et d'écriture connectés uniquement à la SDRAM.

#figure(image("../media/msgdma_loopback.png"), caption: [MSGDMA SDRAM Loopback])

Le même comportement de crash s'est reproduit de manière identique, confirmant que le problème était entre lié aux intéractions DMA-SDRAM et non à notre implémentation.

Après une analyse approfondie, nous avons déterminé que la cause du dysfonctionnement résidait dans la configuration logicielle de notre environnement. Plus précisément, le système Linux utilisé sur le HPS ne disposait pas des fonctionnalités nécessaires pour permettre une gestion correcte des accès DMA, notamment au niveau de la configuration du matériel et des pilotes. Ce problème, relevant de la configuration bas niveau du système et hors de l'objectif de notre projet, n’a malheureusement pas pu être résolu dans ce cadre ci.

== Impact sur le projet

Cette défaillance a eu des conséquences dramatiques sur l'avancement du projet :

- Perte de temps critique : Plusieurs jours de développement ont été consacrés au debugging sans résolution
- Abandon de l'architecture optimale : Impossibilité de maintenir le design haute performance initialement prévu
- Compromis sur la machine d'état : Le temps perdu a empêché le développement de la machine d'état FPGA complexe nécessaire pour gérer jusqu'à 35 fenêtres et lancer les 12 calculs de référence en parallèle

== Leçons apprises

Cette expérience nous a fait prendre conscience de l'importance cruciale des _test benchs_ en développement VHDL.
Si nous avions investi du temps initial dans la création de simulations complètes, nous aurions pu développer et valider la machine d'état indépendamment de la partie logicielle,
évitant ainsi la dépendance critique aux transferts DMA défaillants.

Cette leçon sur l'importance de la validation par simulation constitue un apprentissage fondamental que nous emportons pour notre future carrière d'ingénieurs en informatique embarquée :
toujours séparer et valider individuellement chaque composant avant l'intégration système.

== Fonctionnement DMA 
Bien que le DMA n’ait finalement pas pu être exploité dans ce projet, nous avons tout de même développé une version théoriquement fonctionnelle, en nous appuyant sur le tutoriel REDS fourni pour ce laboratoire. L’implémentation repose sur le bloc MSGDMA d’Altera, conçu pour transférer efficacement des données entre le HPS et notre IP custom, sans intervention directe du processeur. Le MSGDMA est configuré pour lire les données depuis la SDRAM et les écrire dans notre mémoire personnalisée.

Ce schéma devait aboutir à un système tel que présenté ci-dessous :
#figure(image("../media/original_dma.png"), caption: [QSYS avec le DMA])

L'objectif était, via le driver, de préparer les fenêtres de données dans la SDRAM du HPS, puis de configurer le DMA en renseignant les registres CSR (Control and Status Register, permettant d’activer les interruptions, de lancer le transfert, etc.) ainsi que les registres de descripteur (adresse source, adresse destination, taille du transfert, etc.), avant de déclencher le DMA. Celui-ci devait alors lire les données depuis la SDRAM et les écrire dans notre mémoire personnalisée. Cependant, comme mentionné précédemment, le DMA n’a pas pu être exploité dans ce projet en raison de limitations de configuration du système Linux sur le HPS.

== Implémentation du DMA
