= Design du système

== Design initial souhaité

Notre conception originale visait un système optimisé avec les caractéristiques suivantes :

- Mémoire RAM intégrée : Une mémoire directement incluse dans l'IP, avec deux ports
  - Le premier port exposé à l'extérieur avec une interface Avalon dédiée
  - Le deuxième port pour s'interfacer directement depuis notre IP
- Double interface : Interface Avalon pour les accès mémoire et interface AXI séparée pour les registres de configuration
- DMA : Utilisation du bloc IP MSGDMA d'Altera avec port de lecture connecté à la SDRAM HPS et port d'écriture vers le bus Avalon
- Architecture _haute performance_ : Séparation des bus pour maximiser le débit, le bus Avalon étant exclusivement utilisé par le DMA
- Capacité de traitement : Avec une mémoire de 8kB, elle serait capable de stocker 35 fenêtres à calculer, les 12 fenêtres de référence et
  conserver tous les résultats de corrélation

Cette architecture aurait permis un traitement parallèle efficace avec des transferts DMA optimisés et une utilisation _maximale_ des ressources FPGA.

== Design final implémenté

Face aux problèmes techniques rencontrés, nous avons dû simplifier drastiquement notre approche :

- IP simplifiée : Bloc ne gérant que deux fenêtres de maximum 64 échantillons chacune
- Calcul basique : Simple calcul de produit scalaire entre deux buffers
- Traitement séquentiel côté logiciel : Pour chaque fenêtre d'intérêt, envoi séquentiel avec chacune des 12 fenêtres de référence
- Absence de parallélisme : Perte de l'optimisation parallèle initialement prévue

Cette solution, bien que fonctionnelle, représente un compromis important par rapport à nos objectifs de performance initiaux.

Notons que même si nous aurions pu garder le design original (sans le DMA), le temps perdu sur les problèmes liés, nous ont obligés à trouver un compromis
pour avoir quelque chose de fonctionnel.
