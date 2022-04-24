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



VU.add_library("lib")
VU.add_source_files(sim_dir / "tb" / "*.vhd", "lib")
VU.add_source_files(sim_dir / "tb_helpers" / "*.vhd", "lib")

VU.add_source_files(src_dir / "*.vhd", "lib")
VU.add_source_files(src_dir / "cpu" / "*.vhd", "lib", allow_empty=True)
VU.add_source_files(src_dir / "soc" / "*.vhd", "lib", allow_empty=True)
VU.add_source_files(src_dir / "wishbone" / "*.vhd", "lib", allow_empty=True)
VU.add_source_files(src_dir / "packages" / "*.vhd", "lib", allow_empty=True)
VU.add_source_files(src_dir / "peripherals" / "*.vhd", "lib", allow_empty=True)
VU.add_source_files(src_dir / "peripherals" / "common" / "*.vhd", "lib", allow_empty=True)
VU.add_source_files(src_dir / "peripherals" / "uart" / "*.vhd", "lib", allow_empty=True)
VU.add_source_files(src_dir / "peripherals" / "timer" / "*.vhd", "lib", allow_empty=True)

# The GOWIN simulation primitives require the dodgy Synopsys std_logic_arith,
# std_logic_signed and std_logic_unsigned packages, so only include them if necessary
if USE_GOWIN_SIMLIB:
    VU.add_source_files(gowin_simlib, "lib")
    VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "-fsynopsys", "--std=08", "-frelaxed-rules"])
    VU.set_sim_option("ghdl.elab_flags", ["-fsynopsys"])
else:
    VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "--std=08", "-frelaxed-rules"])


VU.main()
