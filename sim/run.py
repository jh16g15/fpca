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

VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "--std=08"])

## need to use "resolve()" to get abspath
# print(f"0:{os.listdir(Path(__file__).resolve().parents[0])}")
# print(f"1:{os.listdir(Path(__file__).resolve().parents[1])}")
# print(f"2:{os.listdir(Path(__file__).resolve().parents[2])}")

sim_dir = Path(__file__).parent / "tb"
src_dir = Path(__file__).resolve().parents[1] / "src"

VU.add_library("lib")
VU.add_source_files(sim_dir / "*.vhd", "lib")
VU.add_source_files(src_dir / "*.vhd", "lib")
VU.add_source_files(src_dir / "packages" / "*.vhd", "lib")




VU.main()