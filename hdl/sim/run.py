#!/usr/bin/env python3

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2021, Lars Asplund lars.anders.asplund@gmail.com

"""
VHDL User Guide
---------------
The most minimal VUnit VHDL project covering the basics of the
:ref:`User Guide <user_guide>`.
"""

from pathlib import Path
from vunit import VUnit
import os
from glob import glob

def add_some_files_to_vunit(vunit_obj, dir, exclude_patterns, library):
    """Adds a list of all VHDL files in a directory structure to Vunit, excluding those in EXCLUDE"""
    print("===================================================")
    print(f"Scanning {dir}")
    glob_pattern=  str(dir) + "/**/*.vhd"
    print(f"for {glob_pattern}")
    print("===================================================")
    file_list = glob(glob_pattern, recursive=True)
    trimmed_file_list = []
    for file in file_list:
        include = True
        for pattern in exclude_patterns:
            if pattern in file:
                include = False
        if include:
            trimmed_file_list.append(file)

    for file in trimmed_file_list:
        print(str(file))
        vunit_obj.add_source_file(file, library)

    return True



def main():
    VU = VUnit.from_argv()
    VU.add_verification_components()

    USE_GOWIN_SIMLIB = True
    gowin_simlib = "/mnt/c/Gowin/Gowin_V1.9.8.03_Education/IDE/simlib/gw1n/prim_sim.vhd"




    ## need to use "resolve()" to get abspath
    # print(f"0:{os.listdir(Path(__file__).resolve().parents[0])}")
    # print(f"1:{os.listdir(Path(__file__).resolve().parents[1])}")
    # print(f"2:{os.listdir(Path(__file__).resolve().parents[2])}")

    sim_dir = Path(__file__).parent
    src_dir = Path(__file__).resolve().parents[1] / "src"
    boards_dir = Path(__file__).resolve().parents[2] / "boards"
    pynq_dir = Path(__file__).resolve().parents[2] / "boards" / "pynq_z2"


    #string pattern match "in"
    sim_exclude = [
        "./vunit_out/ghdl/libraries",
        "./tb_helpers/psram_memory_interface_hs_2ch/temp",
        "./tb_helpers/psram_memory_interface_hs_2ch/",
    ]
    src_exclude = [
        "/mnt/d/Documents/fpga/fpca/hdl/src/wishbone/jtag_wb_master.vhd",
        "/mnt/d/Documents/fpga/fpca/hdl/src/peripherals/hamsterworks_dvi/",
        "/mnt/d/Documents/fpga/fpca/hdl/src/peripherals/display_old/display_top.vhd",
    ]
    boards_exclude = [
        "/mnt/d/Documents/fpga/fpca/boards/pynq_z2/bd/",
        "/mnt/d/Documents/fpga/fpca/boards/pynq_z2/bd/",
        "/mnt/d/Documents/fpga/fpca/boards/pynq_z2/fpca/fpca.ip_user_files/",
        "/mnt/d/Documents/fpga/fpca/boards/pynq_z2/ip",
        "/mnt/d/Documents/fpga/fpca/boards/tang_nano_9k/gowin_sim/",
    ]

    VU.add_library("lib")
    add_some_files_to_vunit(VU, sim_dir, sim_exclude, "lib")
    add_some_files_to_vunit(VU, src_dir, src_exclude, "lib")
    # add_some_files_to_vunit(VU, pynq_dir, boards_exclude, "lib")

    # The GOWIN simulation primitives require the dodgy Synopsys std_logic_arith,
    # std_logic_signed and std_logic_unsigned packages, so only include them if necessary
    if USE_GOWIN_SIMLIB:
        VU.add_source_files(gowin_simlib, "lib")
        VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "-fsynopsys", "--std=08", "-frelaxed-rules"])
        VU.set_sim_option("ghdl.elab_flags", ["-fsynopsys"])
    else:
        VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "--std=08", "-frelaxed-rules"])


    VU.main()


if __name__ == "__main__":
    main()