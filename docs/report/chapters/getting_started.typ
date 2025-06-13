= Guide de démarrage semi-rapide

Ce guide vous propose de compiler vous même le kernel car c'est toujours le bonheur de dire aux gens que l'on compile notre propre noyau.
Si vous le souhaitez pas faire, vous pouvez télécharger tous les fichiers générées par ce guide dans la dernière release github 
#link("https://github.com/HEIG-AndreCosta/scf-dtmf/releases")[ici].

1. Cloner le repository

```bash
git clone --recurse-submodules --shallow-submodules https://github.com/HEIG-AndreCosta/scf-dtmf.git 
cd scf-dtmf
```

2. Compiler le kernel

```bash
cd linux
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
cd ..
```

3. Préparer la carte SD

```bash
cd image
mkimage -f de1soc.its de1soc.itb
# En supposant que votre carte est montée dans /run/media/<username>/BOOT
# Modifiez le chemin si nécessaire
cp de1soc.itb /run/media/$(whoami)/BOOT/de1soc.itb
umount /run/media/$(whoami)/BOOT
cd ..
```

Puis insérez la carte SD dans votre DE1-SoC et démarrez la carte.

4. Flasher la FPGA

Le fichier `.sof` peut être généré à partir de Quartus ou téléchargé de la release Github.

Le script `pgm_fpga.py` fourni au début du semestre se trouve dans le répértoire `scripts`.
N'hésitez à utiliser le vôtre si celui ne convient pas.

```bash
python3 scripts/pgm_fpga.py --sof <path/to/DE1_SoC_top.sof>
```

5. Compiler et déployer le driver

A partir de cette étape, on présume que la DE1 est accessible par ssh à travers l'addresse `192.168.0.2`.

```bash
cd driver
make
scp access.ko root@192.168.0.2:~
cd ..
```

6. Compiler et déployer l'application user-space

```bash
cd dtmf
cmake -DCMAKE_TOOLCHAIN_FILE=arm-linux-gnueabihf.cmake -B build
cmake --build build -j$(nproc)
scp build/dtmf_encdec root@192.168.0.2:~
cd ..
```

7. Connectez-vous à la carte DE1-SoC

```bash
ssh root@ssh root@192.168.0.2
```

8. Insérez le module

```bash
insmod access.ko
```

9. Have fun!

```bash
echo "test" > test.txt
./dtmf_encdec encode test.txt test.wav
./dtmf_encdec decode_fpga test.wav
```
