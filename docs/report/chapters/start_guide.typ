= Guide de démarrage rapide - installation et utilisation

== Prérequis

- Chaîne de compilation croisée `arm-linux-gnueabihf-` installée dans le PATH
- Carte DE1-SoC avec carte SD configurée
- Accès réseau ou UART pour la communication avec la carte

== Compilation du système

=== Construction du noyau Linux

Initialisation des sous-modules Git et compilation du noyau pour l'architecture ARM :

```bash
git submodule update --init
cd linux
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
cd ..
```

=== Génération de l'image ITB

Création de l'image de démarrage et copie sur la partition de boot de la carte SD :

```bash
cd image
mkimage -f de1soc.its de1soc.itb
# Adaptation du chemin selon votre configuration
cp de1soc.itb /run/media/$(whoami)/de1soc.itb
cd ..
```

=== Installation des dépendances

Installation de la bibliothèque libsndfile nécessaire pour le traitement audio :

```bash
sudo apt update
sudo apt install libsndfile1-dev
```

=== Compilation du driver

Construction du module noyau pour l'interface avec l'IP FPGA :

```bash
cd driver
make
cd ..
```

=== Compilation de l'application utilisateur

Construction de l'application de décodage DTMF avec compilation croisée :

```bash
cd dtmf
cmake -DCMAKE_TOOLCHAIN_FILE=arm-linux-gnueabihf.cmake -B build -S .
cmake --build build -j$(nproc)
cd ..
```

== Déploiement sur la carte DE1-SoC

=== Transfert des fichiers

Copie du driver et de l'application sur la carte via SCP :

```bash
scp ./driver/access.ko root@192.168.0.2:/root/
scp ./dtmf/build/dtmf_encdec root@192.168.0.2:/root/
```

=== Connexion à la carte

*Connexion UART :*
```bash
picocom -b 115200 /dev/ttyUSB0
```

*Connexion SSH :*
```bash
ssh root@192.168.0.2
```

== Utilisation du système

=== Chargement du driver

```bash
# Chargement du module
insmod access.ko

# Déchargement du module (si nécessaire)
rmmod access.ko
```

=== Test de l'application

Vérification du bon fonctionnement de l'exécutable :

```bash
./dtmf_encdec
```

=== Encodage et décodage DTMF

*Création d'un fichier test (lettres en minuscules) :*
```bash
echo "hello" > hello.txt
```

*Encodage en signal DTMF :*
```bash
./dtmf_encdec encode hello.txt hello.wav
```

*Décodage avec l'algorithme fréquentiel principal :*
```bash
./dtmf_encdec decode hello.wav
```

*Décodage avec l'algorithme temporel :*
```bash
./dtmf_encdec decode_time_domain hello.wav
```

*Décodage avec l'implémentation FPGA :*
```bash
./dtmf_encdec decode_fpga hello.wav
```

== Notes importantes

- Les fichiers texte d'entrée doivent contenir uniquement des lettres minuscules et des chiffres
- L'IP FPGA doit être correctement configurée avant le chargement du driver
- La connexion réseau doit être établie pour les transferts SCP
