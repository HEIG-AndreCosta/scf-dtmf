#!/bin/bash

set -e

arm-linux-gnueabihf-gcc -o test main.c
scp test root@192.168.0.2:~
ssh root@192.168.0.2 "./test"
