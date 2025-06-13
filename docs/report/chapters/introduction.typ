= Introduction

Ce laboratoire avait pour objectif de développer un système complet de décodage DTMF sur FPGA, intégrant une IP VHDL, un transfert DMA optimisé et un driver Linux.
Cependant, ce projet a été marqué par plusieurs problèmes techniques majeurs qui nous ont contraints à adopter un design simplifié mais fonctionnel,
bien éloigné de notre conception initiale optimale.

Les difficultés rencontrées, principalement liées aux transferts DMA et aux contraintes temporelles du projet,
nous ont obligés à revoir nos ambitions à la baisse et à implémenter une solution moins performante mais opérationnelle.
Ce rapport détaille les choix techniques effectués, les obstacles rencontrés et les compromis adoptés pour mener le projet à terme dans les délais impartis.
