== Driver Linux

=== Architecture générale

Le driver développé pour ce projet est implémenté sous forme de platform driver, s'enregistrant auprès du framework `misc` du noyau Linux
pour fournir une interface simple vers l'espace utilisateur.
Cette approche permet une intégration transparente dans le système de fichiers virtuel et expose le périphérique via le point de montage `/dev/de1_io`,
suivant les conventions standard des périphériques Linux.

=== Validation de l'IP au démarrage

Lors de la phase de probe du driver, un mécanisme de validation vérifie la communication correcte avec l'IP FPGA grâce à deux registres de test :

1. Registre READ-ONLY : Permet de lire une constante prédéfinie pour valider les opérations de lecture
2. Registre READ-WRITE : Permet d'écrire une valeur arbitraire puis de la relire pour valider les opérations d'écriture

Une fois ces tests de validation passés avec succès, la fonction probe peut se terminer correctement et le driver devient opérationnel.
Cette vérification initiale garantit l'intégrité de la communication avec le matériel avant toute utilisation par l'application.

=== Évolution du design

Originellement, le driver avait été conçu pour exploiter pleinement les capacités DMA du système, permettant des transferts mémoire haute performance entre l'HPS et la FPGA.
Cependant, suite aux problèmes critiques rencontrés avec les transferts DMA décrits précédemment, toute la logique DMA a dû être supprimée du driver,
le simplifiant considérablement mais réduisant ses performances.

=== Implémentation DMA originalement prévue

Bien que l'implémentation DMA n'ait pas pu être finalisée en raison des dysfonctionnements critiques rencontrés.
Le driver s'interfaçait initialement avec le contrôleur MSGDMA d'Altera avec les fonctionnalitées suivantes:

- Gestion de la mémoire : Utilisation de l'API Linux `dma_set_mask_and_coherent()` pour configurer le masque DMA 32 bits
- Cache coherence : Emploi de `dma_map_single()` et `dma_unmap_single()` pour assurer la cohérence des caches
- Interruptions : Une interruption permettait au driver de savoir que une écriture avait été réalisée, permettant de libérer les ressources acquises.
- Allocation dynamiques: Utilisation de `kmalloc` avec le flag `GFP_DMA` pour garantir, encore la gestion correcte de la mémoire utilisée pour les transferts

=== Interface utilisateur

Le driver expose uniquement deux opérations à l'espace utilisateur, conformément aux contraintes imposées par notre IP simplifiée :

==== Opération `ioctl`

L'interface `ioctl` centralise toutes les opérations de configuration et de contrôle nécessaires au transfert correct des données vers la FPGA.
Elle implémente les commandes détaillées dans la section précédente, permettant à l'application user-space de configurer les adresses mémoire,
définir les fenêtres à traiter et déclencher les calculs.

==== Opération `read`

La fonction `read` permet de récupérer le résultat du calcul de corrélation le plus récent effectué par la FPGA.
Cette opération est non-bloquante : si aucun résultat n'est disponible, elle retourne immédiatement avec `errno` positionné à `EAGAIN`.

=== Gestion des interruptions

Une interruption générée par la FPGA signale au driver l'achèvement d'un calcul de corrélation.
Le gestionnaire d'interruption modifie un flag interne indiquant qu'un nouveau résultat est disponible, permettant aux appels `read` suivants de récupérer cette donnée fraîche.

=== Gestion des registres et remise à zéro

L'application user-space n'utilise pas nécessairement la totalité des 64 registres disponibles côté FPGA pour ses calculs.
Pour éviter que des valeurs résiduelles d'opérations précédentes n'influencent les nouveaux résultats, l'appel `IOCTL_RESET_DEVICE` remet systématiquement tous les registres à zéro.

Cette précaution est essentielle car la FPGA calcule le produit scalaire sur l'ensemble des 64 échantillons : des valeurs non nulles dans les registres inutilisés fausseraient le résultat
final de manière imprévisible.
