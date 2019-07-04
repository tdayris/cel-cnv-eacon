#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script aims to prepare the design file for EaCoN cnv analysis
"""

import pandas as pd                  # Parse TSV files
import sys                           # System related methods
from argparse import ArgumentParser  # Parse command line
from pathlib import Path             # Paths related methods


def guess_array_type(raw_data: Path) -> str:
    """
    Guess array type, just like its name suggested
    """
    raw_data = Path(raw_data)
    if not raw_data.exists():
        raise FileNotFoundError(f"Could not find: {str(raw_data)}")

    array_type = None
    for file in raw_data.iterdir():
        is_cel = file.name.endswith("CEL")
        is_onco = file.name.endswith("C.CEL") or file.name.endswith("A.CEL")
        if is_cel and not is_onco:
            array_type = "CytoScanHD_Array"
            break
    else:
        array_type = "OncoScan_CNV"

    return array_type


def parse_cyto_dir(cytodir: str, strongr: bool = True) -> pd.DataFrame:
    """
    Build a design file from a cytoscan directory
    """
    # Path to input directory
    cytodir = Path(cytodir)
    print(f"Cytoscan path identified as: {str(cytodir)}", file=sys.stderr)
    # Define column names
    sample = "Sample_id" if strongr else "SampleName"
    cel = "CEL" if strongr else "cel_files"
    # Parse file names
    samples = {
        content.name: {
            sample: str(content.stem),
            cel: str(content.absolute())
        }
        for content in cytodir.iterdir()
        if content.is_file() and content.name.endswith(".CEL")
    }

    return pd.DataFrame(samples).T


def parse_onco_dir(oncodir: str, strongr: bool = True) -> pd.DataFrame:
    """
    Build a design file from a oncoscan directory
    """
    # Path to input directory
    oncodir = Path(oncodir)
    print(f"Oncoscan path identified as: {str(oncodir)}", file=sys.stderr)
    # Define column names
    sample = "Sample_id" if strongr else "SampleName"
    at = "ATChannelCel"
    cg = "GCChannelCel"
    # Parse file names
    samples = {
        content.name: {
            sample: str(content.stem)[:-2],
            at: str(content.absolute()),
            cg: str(content.absolute()).replace("A.CEL", "C.CEL")
        }
        for content in oncodir.iterdir()
        if content.is_file() and content.name.endswith("A.CEL")
    }

    return pd.DataFrame(samples).T


if __name__ == '__main__':
    main_parser = ArgumentParser(
        description="prepare_design aims to generate your design file from "
                    "a given repository.",
        epilog="This script does not make any magic. Please check the prepared"
               " design!",
    )

    main_parser.add_argument(
        "-r", "--rawdata",
        help="Path to raw data directory (default: %(default)s)",
        type=str,
        default="."
    )

    main_parser.add_argument(
        "-d", "--design",
        help="Output path to design file (default: %(default)s)",
        type=str,
        default="design.tsv"
    )

    main_parser.add_argument(
        "-e", "--eacon",
        help="Design file is meant to be used by EaCoN itself, "
             "and not STRonGR",
        action="store_false"
    )

    args = main_parser.parse_args()
    if guess_array_type(Path(args.rawdata)) == "CytoScanHD_Array":
        data = parse_cyto_dir(str(args.rawdata), args.eacon is True)
    else:
        data = parse_onco_dir(str(args.rawdata), args.eacon is True)

    print(data.head(), file=sys.stderr)
    data.to_csv(args.design, sep="\t", index=False)
