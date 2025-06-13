= Notre IP

== Présentation de l'IP
Comme cité plutôt, l’IP que nous devions concevoir dans le cadre de ce laboratoire est un décodeur DTMF (Dual-Tone Multi-Frequency) capable de traiter jusqu’à 35 fenêtres de 57 échantillons chacune, pour un total de 12 calculs de référence en parallèle. L’objectif initial était de réaliser un système intégrant une mémoire de 8'192 octets, sa gestion, ainsi qu’un processus de décodage DTMF. L’IP devait pouvoir charger les fenêtres d’analyse et de référence depuis la mémoire interne, puis effectuer les calculs de corrélation entre chaque fenêtre d’analyse et les fenêtres de référence. Les résultats de ces calculs devaient être stockés dans des registres, accessibles directement par le HPS via une interface AXI. L’ensemble du fonctionnement devait être orchestré par une machine d’états complexe, assurant la gestion des différentes étapes du processus de décodage DTMF.

== Réalités de l'IP
En raison de difficultés techniques rencontrées lors de l’implémentation du DMA et de la gestion de la mémoire, ainsi que du temps limité, il n’a pas été possible de réaliser l’IP dans sa version initialement prévue. Nous avons donc opté pour une version simplifiée, capable de gérer une seule fenêtre d’analyse et une seule fenêtre de référence de 64 échantillons maximum chacun. Le calcul de corrélation se limite à un produit scalaire (dot product), dont le résultat est stocké dans des registres accessible. Le processus de corrélation est déclenché sur demande du HPS et géré par une logique séquentielle simplifiée.

== Interfaces de l'IP
L’IP propose deux interfaces principales :

- **Interface AXI4-Lite** : Cette interface, basée sur l’IP développée lors du laboratoire 6, permet la communication avec le HPS. Elle assure la gestion des registres de configuration et de statut, le déclenchement du calcul de corrélation, ainsi que la gestion des interruptions pour signaler la fin du traitement. La majorité de la logique AXI4-Lite est réutilisée, seules les parties spécifiques au décodage DTMF ont été adaptées.

- **Interface Avalon** : Destinée à l’accès à la mémoire interne de l’IP, cette interface permet au HPS ou au DMA de lire et d’écrire des données, ainsi que de configurer certains paramètres. Toutefois, comme mentionné précédemment, l’implémentation complète de la mémoire n’a pas pu être réalisée dans ce projet, et cette interface reste principalement illustrative de la structure initialement envisagée.

== Remplacement de la mémoire
Face aux difficultés rencontrées lors de l’implémentation de la mémoire interne, nous avons opté pour une solution de remplacement basée sur des tableau de registres. Ces tableaux permettent de stocker les fenêtres d’analyse et de référence, tandis que le résultat du calcul de corrélation (sur 64 bits) est réparti dans deux registres de 32 bits. Bien que cette approche consomme davantage de ressources FPGA et ne soit pas optimale, elle nous a permis de valider le fonctionnement de l’IP en contournant les limitations liées à la gestion mémoire. Le bus Avalon dédié à la mémoire a néanmoins été conservé, illustrant la structure cible de l’IP telle qu’elle avait été initialement conçue.

== Plan d'addressage
L’IP est organisée de manière à permettre un accès direct aux registres de configuration et de statut, ainsi qu’aux tableaux de données. Le plan d’adressage est le suivant :
#include "address_mapping_table.typ"

== Calcul de corrélation
Le calcul de corrélation est réalisé en effectuant un produit scalaire entre la fenêtre d’analyse et la fenêtre de référence. Voici notre implémentation simplifiée :
```vhdl
    process(clk_i, rst_i)
        variable temp_sum : signed(63 downto 0);
        variable abs_temp_sum : signed(63 downto 0);
    begin
        if rst_i = '1' then
            calculation_done <= '0';
            dot_product <= (others => '0');
        elsif rising_edge(clk_i) then
            if calculation_done = '1' then
                calculation_done <= '0';
            end if;

            if start_calculation = '1' then
                temp_sum := (others => '0');
                for i in 0 to 63 loop
                    temp_sum := temp_sum + (signed(window_samples_s(i)) * signed(ref_samples_s(i)));
                end loop;
                if temp_sum < 0 then
                    abs_temp_sum := -temp_sum;
                else
                    abs_temp_sum := temp_sum;
                end if;
                dot_product <= abs_temp_sum;
                calculation_done <= '1';
            end if;
        end if;
    end process;
```
Cette méthode de corrélation repose sur le calcul du produit scalaire, selon la formule suivante, utilisée dans le projet DTMF original en C :
```c
int64_t dot = 0;
	for (size_t i = 0; i < len; ++i) {
		dot += x[i] * y[i];
	}
	return dot >= 0 ? dot : -dot;
```
