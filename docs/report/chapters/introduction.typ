= Introduction

Ce rapport présente le développement d'un système de décodage DTMF (Dual-Tone Multi-Frequency) sur FPGA réalisé dans le cadre du laboratoire final du cours System on Chip on FPGA (SCF). 

== Contexte

Le DTMF est un système d'encodage utilisé dans les télécommunications où chaque touche de clavier téléphonique génère une combinaison unique de deux fréquences. L'objectif de ce laboratoire est de réimplémenter en VHDL un algorithme de décodage DTMF fourni, en optimisant les transferts de données par DMA.

== Architecture développée

Le système s'articule autour de quatre composants principaux :

+ *IP VHDL de corrélation* : Module matériel implémentant l'algorithme de décodage par corrélation
+ *Contrôleur DMA* : Module gérant les transferts de données entre la mémoire HPS et l'IP FPGA
+ *Driver Linux* : Pilote gérant l'interface entre l'IP et l'espace utilisateur, configurant les transferts DMA et les interruptions
+ *Application utilisateur* : Programme de décodage de fichiers audio WAV exploitant l'IP via le driver

Cette architecture permet de décharger le processeur des transferts de données, optimisant ainsi les performances du système.

== Défis techniques

Les principales contraintes du projet incluent :
- Utilisation exclusive des blocs mémoires internes du FPGA
- Optimisation des transferts DMA entre HPS et FPGA  
- Synchronisation matérielle-logicielle via interruptions
- Traitement temps réel des signaux audio

== Organisation du rapport

Ce rapport détaille successivement la conception de l'IP VHDL, l'implémentation du driver Linux, le développement de l'application utilisateur, ainsi que la validation et l'analyse des performances du système complet.