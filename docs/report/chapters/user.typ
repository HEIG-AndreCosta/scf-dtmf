= Application User-Space

== Base logicielle existante
L'application user-space développée pour ce laboratoire s'appuie sur le programme créé lors du cours de HPC (High Performance Coding). Ce programme offrait initialement trois fonctionnalités principales :

- Encodage DTMF : Génération d'un fichier audio WAV à partir d'un fichier texte d'entrée
- Décodage fréquentiel : Analyse du signal DTMF par transformée de Fourier rapide (FFT)
- Décodage temporel : Décodage par corrélation utilisant le produit scalaire (dot product)

== Adaptations nécessaires

Le travail effectué pour ce laboratoire a consisté à intégrer le décodage matériel FPGA à cette base existante.
Cette intégration a nécessité l'implémentation de l'algorithme en trois phases décrit précédemment, une approche différente des algorithmes existants.

Les algorithmes fréquentiel et de corrélation originaux fonctionnaient en traitement direct : ils parcouraient le fichier audio, détectaient une fenêtre d'intérêt,
la décodaient immédiatement et généraient le résultat en temps réel. Cette approche séquentielle ne se prêtait pas à la parallélisation matérielle envisagée.

Le nouvel algorithme en trois phases (extraction, corrélation, reconstruction) a été spécifiquement conçu pour faciliter l'interfaçage avec le matériel FPGA et permettre un
traitement parallèle des fenêtres d'intérêt.

== Traitement du fichier audio

L'application commence par lire et valider le fichier `WAVE` d'entrée, vérifiant que toutes les contraintes sont respectées :

- Format 16 bits par échantillon
- Fréquence d'échantillonnage de 8000 Hz
- Présence d'une pression initiale pour la calibration

Une fois ces vérifications effectuées, le fichier est traité selon l'algorithme en trois phases avant l'interfaçage avec le driver FPGA.

== Approche originale envisagée

L'interface initialement conçue visait une utilisation optimisée du matériel FPGA avec un minimum de communications entre le software et le hardware. Le protocole prévu était le suivant :

- Configuration unique des références : Un seul appel `ioctl` pour transférer l'ensemble des 12 fenêtres de référence DTMF vers la mémoire FPGA
- Configuration du signal d'entrée : Un seul appel `ioctl` pour indiquer l'adresse du buffer contenant tout le signal audio
- Transfert par lot des fenêtres : Itération avec `ioctl` pour chaque fenêtre d'intérêt, déclenchant des transferts DMA en arrière-plan
- Traitement parallèle massif : Une fois le nombre maximum de fenêtres transférées (jusqu'à 35), un appel à `read` aurait lancé le calcul parallèle de 
  corrélation bloquant l'application user-space en attendant la fin du résultat, diminuant considèrablement l'utilisation CPU

Cette approche aurait permis deux niveaux de parallélisation selon la quantité de logique disponible au niveau hardware:

- Parallélisation maximale : 35 × 12 = 420 calculs de corrélation simultanés (si les ressources FPGA le permettaient)
- Parallélisation par fenêtre : Au minimum, les 12 calculs de corrélation pour chaque fenêtre en parallèle

Cette architecture aurait considérablement réduit la charge du processeur et optimise l'utilisation des ressources FPGA.

== Solution finale implémentée

Malheureusement, les problèmes critiques rencontrés avec le DMA et le temps perdu en debugging nous ont contraints à adopter une solution beaucoup moins efficace
qui reporte la majorité du travail sur le software.

=== Interface avec le driver

Le driver Linux tel qu'implémenté utilise plusieurs commandes IOCTL pour configurer et contrôler l'IP FPGA :

```c
#define IOCTL_SET_WINDOW_SAMPLES  0
#define IOCTL_SET_SIGNAL_ADDR     1
#define IOCTL_SET_WINDOW          3
#define IOCTL_SET_REF_WINDOW      4
#define IOCTL_START_CALCULATION   5
#define IOCTL_SET_REF_SIGNAL_ADDR 6
#define IOCTL_RESET_DEVICE        7
```

=== Séquence d'utilisation

L'interfaçage avec le driver suit un protocole bien défini :

==== Phase de configuration initiale

- `IOCTL_SET_WINDOW_SAMPLES` : Définit le nombre total d'échantillons à traiter
- `IOCTL_SET_SIGNAL_ADDR`: Spécifie l'adresse du buffer mémoire user-space contenant le signal d'entrée
- `IOCTL_SET_REF_SIGNAL_ADDR` : Indique l'adresse du buffer contenant les fenêtres de référence

==== Phase de traitement par fenêtre

Pour chaque fenêtre d'intérêt identifiée lors de la phase d'extraction :

1. `IOCTL_SET_WINDOW` : Spécifie l'offset de la fenêtre dans le signal d'entrée
2. Itération sur les 12 boutons DTMF :
  - Pour chaque fenêtre de référence :
    - `IOCTL_SET_REF_WINDOW` : Définition de l'offset depuis l'adresse de référence
    - `IOCTL_START_CALCULATION` : Lancement du calcul de corrélation matériel
3. Récupération du résultat : Appel à `read` pour obtenir le résultat du produit scalaire

=== Gestion de la synchronisation

Le driver implémente une gestion non-bloquante des calculs. Si le résultat n'est pas encore disponible lors de l'appel à `read`,
la variable `errno` est positionnée à `EAGAIN`, permettant à l'application de gérer l'attente ou de poursuivre d'autres traitements en parallèle.

Cette approche offre une flexibilité d'utilisation qui permet à l'application user-space de faire autre chose si le résultat n'est pas prêt.
