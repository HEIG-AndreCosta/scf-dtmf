= Démarrage du projet

Pour lancer notre projet, suivez les étapes ci-dessous :

1. **Build le kernel**  
  ```
  git submodule update --init
  cd linux
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_defconfig
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
  cd ..
  ```

2. **Build l'image ITB et l'ajouter à la partition BOOT de votre SDCARD**  
  ```
  cd image
  mkimage -f de1soc.its de1soc.itb
  # En supposant que votre carte est montée dans /run/media/<username>/BOOT
  # Modifiez le chemin si nécessaire
  cp de1soc.itb /run/media/$(whoami)/de1soc.itb
  cd ..
  ```
  Puis insérez la carte SD dans votre DE1-SoC et démarrez la carte.

3. **Build le driver**  
  ```
  cd driver
  make
  scp access.ko root@192.168.0.2:~
  cd ..
  ```

4. **Build l'application user-space**  
  ```
  cd dtmf
  cmake -DCMAKE_TOOLCHAIN_FILE=arm-linux-gnueabihf.cmake -B build -S .
  cmake --build build -j$(nproc)
  scp dtmf_encdec root@192.168.0.2:~
  cd ..
  ```

5. **Flash le .sof**
  Compilez au préalable le projet Quartus pour générer le fichier `.sof`, pui:
  ```
  cd eda
  python3 pgm_fpga.py -s=output_files/DE1_SoC_top.sof
  cd ..
  ```

6. **Connectez-vous à la carte DE1-SoC**
  En supposant que vous avez configuré votre carte pour utiliser SSH, vous pouvez vous connecter en utilisant la commande suivante :
  ```
  ssh root@ssh root@192.168.0.2
  ```

7. **Insérez le module du driver**
   Une fois connecté à la carte, insérez le module du driver :
   ```
   insmod access.ko
   ```
8. **Lancez l'application user-space**
    Avant de démarrez le décodage il vous faudra générer un fichier wav encoder, pour ce faire utilisez les commandes suivantes :
    ```
    Créer le fichier texte que vous souhaitez encoder
    echo "test" > test.txt
    ./dtmf_encdec encode test.txt test.wav
    puis décoder votre fichier wav
    ./dtmf_encdec decode test.wav
    ```
