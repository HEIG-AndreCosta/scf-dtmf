Project for the Terasic DE1-Soc board

This projects lit the HPS user LED when the HPS user button is pressed.


How to run the project:
    - compile Quartus project (located in hard/eda/DE1_SoC.qpf), do not forget to generate Qsys project before otherwise Quartus will remind you
    - open Altera Monitor Program, open the corresponding project located in soft/proj
    - Load the board with the .sof file (when prompted by Altera Monitor Program), compile the source files and load the processor
    - Run


How the example works:
    - Pressing HPS user button lit HPS user LED.



folder structure:
    - doc: documentation
    - hard: files related to hardware, ie VHDL source and simulation files, Quartus and Qsys project
    - publi: publications
    - soft: files related to software, ie linux files and project, Altera Monitor Program source and project files
