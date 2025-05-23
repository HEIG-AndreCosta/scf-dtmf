SHELL := /bin/bash

EXCLUDE_DIR={./doc,./publi,./hard/script,./hard/sim,./hard/tb,./hard/eda/db,./hard/eda/hps_isw_handoff,./hard/eda/incremental_db,./hard/eda/output_files,./hard/eda/qsys_system,./hard/eda/simulation,./hard/eda/.qsys_edit,./soft/build,./soft/test}
EXCLUDE_FILES={./hard/eda/*.tcl~,./hard/eda/*.txt,./hard/eda/*.csv,./hard/eda/*.qws,./hard/eda/*.sopcinfo,./soft/proj/*.axf,./soft/proj/*.objdump,./soft/proj/*.srec}

zip:
	tar --exclude=$(EXCLUDE_DIR) --exclude=$(EXCLUDE_FILES) -zcf ../hps_gpio.tar.gz .
