= Contraintes du système

== Contraintes temporelles du signal DTMF

Pour ce laboratoire, nous nous sommes basés sur l'implémentation développée lors du cours de HPC (High Performance Coding),
en conservant les mêmes contraintes temporelles pour assurer la cohérence du système :

- Temps de pression : 0.2 secondes par touche pressée
- Silence entre pressions non consécutives : 0.2 secondes minimum
- Silence entre pressions consécutives : 0.05 secondes minimum

Ces contraintes permettent de définir un protocole de communication clair et prévisible, facilitant l'implémentation de l'algorithme de décodage.

== Contraintes liées à l'algorithme

Une contrainte importante de notre approche algorithmique est que le fichier audio doit impérativement commencer par une pression de touche. Cette première pression sert de référence pour calibrer le système et garantir un alignement correct avec le signal d'entrée. Sans cette calibration initiale, l'algorithme ne peut pas fonctionner de manière fiable.

== Contraintes du format audio

Le système traite exclusivement des fichiers audio au format WAV avec les caractéristiques suivantes :

Résolution : 16 bits par échantillon
Fréquence d'échantillonnage : 8000 Hz

Ce format correspond aux standards téléphoniques classiques et assure une compatibilité avec les signaux DTMF standards.
