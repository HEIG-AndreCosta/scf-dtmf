#!/usr/bin/python3

from subprocess import Popen, PIPE
import os
from os import path
import argparse, sys

#QUARTUS_DIR = "/opt/intelFPGA/18.1/quartus/"
QUARTUS_DIR = "/home/patrick/intelFPGA/23.1std/quartus/"

def run(command):

    my_env = os.environ.copy()
    my_env["PATH"] = QUARTUS_DIR + "/bin64/:" + my_env["PATH"]

    process = Popen(command, env=my_env, stdout=PIPE, shell=True)

    while True:
        line = process.stdout.readline().rstrip()
        if not line:
            break

        # Kill when waiting for gdb connection
        if line == b'Starting GDB Server.':
            process.kill()
            break

        yield line

if __name__ == "__main__":


    parser=argparse.ArgumentParser()

    parser.add_argument('--sof', '-s', help="sof file to program FPGA", type=str)


    args=parser.parse_args()

    if args.sof:
        sof_file = args.sof
        if not path.exists(sof_file):
            print(sof_file + " doesn't exist")
            exit()
        print("**********************LOAD SOF FILE**********************")
        for output in run("quartus_pgm -c 1 -m jtag -o \"P;" + sof_file + "@2\""):
            print(output.decode())

    if not args.sof:
        parser.print_help()
