= Conclusion
Ce projet de décodage DTMF sur FPGA s’est conclu avec une solution fonctionnelle, mais a connu plusieurs difficultés. Si le système final répond aux spécifications et décode correctement les signaux, le développement a été freiné par des problèmes techniques, notamment la gestion de la mémoire et la synchronisation des composants.

Ces contraintes nous ont poussés à simplifier notre design initial. L’architecture haute performance prévue a été abandonnée au profit d’une version plus simple, faute de temps et de moyens pour gérer le débogage et les optimisations.

Malgré cela, le projet a permis de valider l’approche choisie et de poser des bases solides pour de futures améliorations. Parmi les pistes envisageables :

- Exploiter davantage le parallélisme de la FPGA
- Intégrer des traitements du signal plus avancés (comme la FFT)
- Lever certaines limitations techniques (échantillonnage à 8000 Hz, taille fixe des fenêtres d’analyse)

Nous retenons aussi une leçon clé : valider chaque composant séparément avant de tout intégrer est essentiel. Cette rigueur aurait permis de gagner beaucoup de temps.
L'investissement de quelques heures dans la conception et l'implémentation de bancs de test appropriés aurait potentiellement économisé plusieurs jours de débogage intensif
en phase finale de développement.

En résumé, même si les performances ne sont pas optimales, ce projet nous a permis d’atteindre un résultat concret et d’acquérir une vraie expérience en conception de systèmes embarqués. C’est un bon point de départ pour aller plus loin.