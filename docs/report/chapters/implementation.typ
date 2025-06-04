= Implémentation du décodeur DTMF

== Architecture générale

L'implémentation du système de décodage DTMF a été décomposée en quatre composants principaux afin de faciliter le développement et la maintenance du système :

- *IP VHDL de corrélation* (`correlation`) : Module matériel implémentant l'algorithme de décodage DTMF par corrélation, gérant la mémoire interne et les calculs
- *Contrôleur DMA* (`msgdma`) : Module gérant les transferts automatiques de données entre la mémoire HPS et l'IP FPGA sans intervention du processeur
- *Driver Linux* (`access.ko`) : Pilote de périphérique assurant l'interface entre l'espace noyau et l'espace utilisateur, gérant les interruptions et les transferts DMA
- *Application utilisateur* (`dtmf_encdec`) : Programme permettant l'encodage et le décodage de fichiers audio contenant des séquences DTMF

Cette décomposition modulaire permet une approche de développement incrémentale où chaque composant peut être testé et validé indépendamment avant l'intégration dans le système complet.

== Architecture IP VHDL de corrélation

=== Principe de fonctionnement

L'IP de corrélation implémente un algorithme de décodage basé sur la corrélation entre les fenêtres d'échantillons audio reçues et des signaux de référence DTMF pré-calculés. Elle est caractérisée par :

- Une interface Avalon Memory-Mapped Slave pour l'accès aux registres de configuration
- Une interface Avalon Memory-Mapped Master pour la réception des données via DMA
- Une mémoire interne dual-port pour stocker les fenêtres et les signaux de référence
- Une machine à états finis gérant le processus de corrélation

=== Machine d'états

Les états principaux de la machine à états sont :
- `IDLE` : Attente du signal de démarrage de calcul
- `LOAD_WINDOW` : Chargement des paramètres de fenêtre et de référence
- `READ_WINDOW_SAMPLE` / `WAIT_WINDOW_SAMPLE` : Lecture des échantillons de la fenêtre
- `READ_REF_SAMPLE` / `WAIT_REF_SAMPLE` : Lecture des échantillons de référence
- `CORRELATE_SAMPLES` : Calcul du produit scalaire échantillon par échantillon
- `COMPUTE_CORRELATION` : Accumulation des produits scalaires
- `CHECK_BEST_MATCH` : Comparaison avec la meilleure corrélation trouvée
- `STORE_RESULT` : Stockage du résultat dans les registres de sortie
- `COMPLETE` : Génération de l'interruption de fin de calcul

=== Caractéristiques

- *Contraintes mémoire* : Utilisation exclusive des blocs mémoires internes du FPGA (4KB pour les fenêtres, 2KB pour les signaux de référence)
- *Nombre de fenêtres* : Support de 32 fenêtres maximum par calcul
- *Signaux de référence* : 12 signaux correspondant aux boutons DTMF standard
- *Interface interruption* : Génération d'IRQ à la fin du traitement

== Architecture DMA

=== Principe de fonctionnement

Le contrôleur DMA (msgdma) d'Intel/Altera gère les transferts de données entre la mémoire HPS et l'IP FPGA. Il est configuré pour :

- Lecture depuis la mémoire SDRAM du HPS (adresses virtuelles fournies par le driver)
- Écriture vers la mémoire interne de l'IP de corrélation
- Génération d'interruptions en fin de transfert
- Support des transferts en rafales pour optimiser les performances

=== Configuration DMA

```vhdl
-- Configuration du descripteur DMA
MSGDMA_DESC_READ_ADDR_REG    : Adresse source en mémoire HPS
MSGDMA_DESC_WRITE_ADDR_REG   : Adresse destination dans l'IP
MSGDMA_DESC_LEN_REG          : Taille du transfert en octets
MSGDMA_DESC_CTRL_REG         : Contrôle et déclenchement du transfert
```

== Implémentation du driver Linux

=== Architecture du driver

Le driver implémente un périphérique caractère (`/dev/de1_io`) avec les fonctionnalités suivantes :

- *Interface ioctl* : Configuration de la taille des fenêtres et déclenchement des calculs
- *Interface write* : Transfert des signaux de référence vers l'IP
- *Interface read* : Récupération des résultats de décodage
- *Gestion des interruptions* : Handlers pour les IRQ DMA et de fin de calcul

=== Gestion mémoire

```c
// Allocation de mémoire DMA-cohérente
dma_addr_t dma_handle = dma_map_single(priv->dev, buffer, count, DMA_TO_DEVICE);

// Configuration du transfert DMA
msgdma_push_descr(priv->mem_ptr, dma_handle, dst_addr, count, flags);
```

=== Synchronisation

Le driver utilise des mécanismes de synchronisation Linux :
- `completion` pour attendre la fin des calculs et transferts DMA
- `wait_for_completion()` pour bloquer les appels utilisateur jusqu'à la fin des opérations

== Application utilisateur

=== Fonctionnalités

L'application `dtmf_encdec` propose quatre modes de fonctionnement :

```bash
# Encodage d'un fichier texte en signal DTMF
./dtmf_encdec encode input.txt output.wav

# Décodage fréquentiel (FFT)
./dtmf_encdec decode input.wav

# Décodage temporel (corrélation logicielle)
./dtmf_encdec decode_time_domain input.wav

# Décodage FPGA (corrélation matérielle)
./dtmf_encdec decode_fpga input.wav
```

=== Interface avec l'IP FPGA

Pour le mode FPGA, l'application :
1. Génère les signaux de référence DTMF
2. Les transmet à l'IP via l'interface write du driver
3. Découpe le signal audio en fenêtres
4. Configure les transferts DMA via les appels ioctl
5. Récupère les résultats via l'interface read

== Contraintes et optimisations

=== Limitations mémoire

L'utilisation exclusive des blocs mémoires internes impose :
- Taille maximale des fenêtres : 2048 échantillons
- Nombre maximal de fenêtres traitées simultanément : 32
- Fragmentation des transferts DMA pour respecter les contraintes mémoire

=== Optimisations performances

- *Pipeline des calculs* : Traitement en parallèle de plusieurs fenêtres
- *Transferts DMA optimisés* : Utilisation de rafales pour minimiser la latence
- *Gestion des interruptions* : Réduction de la latence de réponse du système

== Validation et tests

=== Tests unitaires

Chaque composant a été testé individuellement :
- IP de corrélation : Validation avec des signaux DTMF synthétiques
- Driver : Tests de transferts DMA et gestion des interruptions
- Application : Comparaison des résultats entre les différents algorithmes

=== Tests d'intégration

Le système complet a été validé avec :
- Fichiers audio de complexité variable
- Mesures de performances et de latence
- Tests de robustesse avec signaux bruités
