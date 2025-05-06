#!/usr/bin/env python3
from pathlib import Path
import resource
from glob import glob
from vunit import VUnit

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
    
    VU = VUnit.from_argv()

    VU.add_vhdl_builtins()
    VU.add_verification_components()

    sim_tb_dir = Path(__file__).parent / "tb"
    sim_helpers_dir = Path(__file__).parent / "tb_helpers"
    sim_helpers_exclude = [
        "psram_memory_interface_hs_2ch/temp",
        "psram_memory_interface_hs_2ch/",
        "sim_psram_aps6404_no_vunit.vhd",
    ]
    src_dir = Path(__file__).resolve().parents[1] / "src"
    src_exclude = [
    # ]
        "wishbone/jtag_wb_master.vhd",
        "peripherals/hamsterworks_dvi/",
        "peripherals/display_old/display_top.vhd",
    ]
    boards_dir = Path(__file__).resolve().parents[2] / "boards"
    pynq_dir = Path(__file__).resolve().parents[2] / "boards" / "pynq_z2"


    VU.add_library("lib")
    # Ignore the "no-ci" testbench folder
    VU.add_source_files(sim_tb_dir / "*.vhd", "lib")
    VU.add_source_files(sim_tb_dir / "riscv-gen2/**/*.vhd", "lib")
    VU.add_source_files(src_dir / "../../tools/**/*.vhd", "lib")
    add_some_files_to_vunit(VU, sim_helpers_dir, sim_helpers_exclude, "lib")
    add_some_files_to_vunit(VU, src_dir, src_exclude, "lib")
    
    xpm_dir = Path(__file__).resolve().parents[1] / "xpm_vhdl"
    VU.add_library("xpm")
    VU.add_source_files(xpm_dir / "src/xpm/*.vhd", "xpm")
    VU.add_source_files(xpm_dir / "src/xpm/xpm_cdc/hdl/*.vhd", "xpm")
    VU.add_source_files(xpm_dir / "src/xpm/xpm_memory/hdl/*.vhd", "xpm")
    VU.add_source_files(xpm_dir / "src/xpm/xpm_fifo/hdl/*.vhd", "xpm")

    unsim_ci_dir = Path(__file__).parent / "unisim_ci"
    VU.add_library("unisim")
    VU.add_source_files(unsim_ci_dir / "**/*.vhd", "unisim")

    # GHDL compile options (allow attributes on ports etc)
    VU.add_compile_option("ghdl.a_flags", ["--ieee=standard", "--std=08", "-frelaxed-rules", "-frelaxed"])

    # allow for shared variables without protected types
    VU.set_sim_option("ghdl.elab_flags", ["-frelaxed-rules"])

    # Increase the maximum size  of a single object to get rid of this error
    # /usr/local/bin/ghdl:error: declaration of a too large object (144 > --max-stack-alloc=128 KB)
    VU.set_sim_option("ghdl.sim_flags", ["--max-stack-alloc=256", "--ieee-asserts=disable"]) # value is in KB

    VU.main()

if __name__ == "__main__":
    main()