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

from importlib import resources
from pathlib import Path
from vunit import VUnit
import os
from glob import glob
import resource

def add_some_files_to_vunit(vunit_obj, dir, exclude_patterns, library):
    """Adds a list of all VHDL files in a directory structure to Vunit, excluding those in EXCLUDE"""
    print("===================================================")
    print(f"Scanning {dir}")
    glob_pattern=  str(dir) + "/**/*.vhd"
    print(f"for {glob_pattern}")
    print(f"Excluding {exclude_patterns}")
    print("===================================================")
    file_list = glob(glob_pattern, recursive=True)
    trimmed_file_list = []
    for file in file_list:
        include = True
        for pattern in exclude_patterns:
            if str(pattern) in file:
                include = False
        if include:
            trimmed_file_list.append(file)

    for file in trimmed_file_list:
        #print(str(file))
        vunit_obj.add_source_file(file, library)

    return True



def main():

    # increase stack size to prevent GHDL crashing
    resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

    VU = VUnit.from_argv(compile_builtins=False)
    VU.add_vhdl_builtins()
    VU.add_verification_components()
    print(f"Added verification components to library!")
    USE_GOWIN_SIMLIB = False # needed for simple_dual_port RAM block (TODO: replace this!)
    gowin_simlib = "/mnt/c/Gowin/Gowin_V1.9.8.03_Education/IDE/simlib/gw1n/prim_sim.vhd"

    USE_XILINX_UNISIM = True
    USE_XILINX_XPM = True
    FPGA_DIR = Path("/mnt/c/Users/joehi/Documents/fpga")
    VIVADO_VERSION = "2023.2"

    VIVADO_DIR = Path(f"/mnt/c/Xilinx/Vivado/{VIVADO_VERSION}")
    xilinx_unisim_dir = VIVADO_DIR / "data/vhdl/src/unisims"
    xilinx_xpm_dir = VIVADO_DIR / "data/ip/xpm"
    xilinx_xpm_vhdl = FPGA_DIR / "xpm_vhdl/src/xpm"    
    xilinx_exclude = [
        "secureip",
        "retarget",
        "**/simulation"
    ]


    ## need to use "resolve()" to get abspath
    # print(f"0:{os.listdir(Path(__file__).resolve().parents[0])}")
    # print(f"1:{os.listdir(Path(__file__).resolve().parents[1])}")
    # print(f"2:{os.listdir(Path(__file__).resolve().parents[2])}")

    sim_tb_dir = Path(__file__).parent / "tb"
    sim_helpers_dir = Path(__file__).parent / "tb_helpers"
    sim_helpers_exclude = [
        "psram_memory_interface_hs_2ch/temp",
        "psram_memory_interface_hs_2ch/",
        "sim_psram_aps6404_no_vunit.vhd",
    ]
    src_dir = Path(__file__).resolve().parents[1] / "src"
    src_exclude = [
        FPGA_DIR / "fpca/hdl/src/wishbone/jtag_wb_master.vhd",
        FPGA_DIR / "fpca/hdl/src/peripherals/hamsterworks_dvi/",
        FPGA_DIR / "fpca/hdl/src/peripherals/display_old/display_top.vhd",
    ]
    boards_dir = Path(__file__).resolve().parents[2] / "boards"
    pynq_dir = Path(__file__).resolve().parents[2] / "boards" / "pynq_z2"
    boards_exclude = [
        FPGA_DIR / "fpca/boards/pynq_z2/bd/",
        FPGA_DIR / "fpca/boards/pynq_z2/bd/",
        FPGA_DIR / "fpca/boards/pynq_z2/fpca/fpca.ip_user_files/",
        FPGA_DIR / "fpca/boards/pynq_z2/ip",
        FPGA_DIR / "fpca/boards/tang_nano_9k/gowin_sim/",
    ]

    VU.add_library("lib")
    VU.add_source_files(sim_tb_dir / "**/*.vhd", "lib")
    add_some_files_to_vunit(VU, sim_helpers_dir, sim_helpers_exclude, "lib")
    add_some_files_to_vunit(VU, src_dir, src_exclude, "lib")
    # add_some_files_to_vunit(VU, pynq_dir, boards_exclude, "lib")

    # The GOWIN simulation primitives require the dodgy Synopsys std_logic_arith,
    # std_logic_signed and std_logic_unsigned packages, so only include them if necessary
    if USE_GOWIN_SIMLIB:
        VU.add_source_files(gowin_simlib, "lib")
        VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "-fsynopsys", "--std=08", "-frelaxed-rules"])
        VU.set_sim_option("ghdl.elab_flags", ["-fsynopsys"])
    else:
        VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "--std=08", "-frelaxed-rules", "-frelaxed"])

    # allow for shared variables without protected types
    VU.set_sim_option("ghdl.elab_flags", ["-frelaxed-rules"])

    if USE_XILINX_UNISIM:
        VU.add_library("unisim")
        # add_some_files_to_vunit(VU, xilinx_unisim_dir, xilinx_exclude, "unisim")
        VU.add_source_files(xilinx_unisim_dir / "unisim_VCOMP.vhd", "unisim")
        VU.add_source_files(xilinx_unisim_dir / "unisim_VPKG.vhd", "unisim")
        VU.add_source_files(xilinx_unisim_dir / "primitive" / "ODDR.vhd", "unisim")
        VU.add_compile_option("ghdl.a_flags", ["-frelaxed-rules", "-frelaxed"])
        
    if USE_XILINX_XPM:
        VU.add_library("xpm")
        VU.add_source_files(Path(xilinx_xpm_vhdl) / "xpm_cdc/hdl/*.vhd", "xpm")
        VU.add_source_files(Path(xilinx_xpm_vhdl) / "xpm_fifo/hdl/*.vhd", "xpm")
        VU.add_source_files(Path(xilinx_xpm_vhdl) / "xpm_memory/hdl/*.vhd", "xpm")
        VU.add_source_files(Path(xilinx_xpm_vhdl) / "xpm_VCOMP.vhd", "xpm")

    # Increase the maximum size  of a single object to get rid of this error
    # /usr/local/bin/ghdl:error: declaration of a too large object (144 > --max-stack-alloc=128 KB)
    VU.set_sim_option("ghdl.sim_flags", ["--max-stack-alloc=256", "--ieee-asserts=disable"]) # value is in KB

    VU.main()


if __name__ == "__main__":
    main()