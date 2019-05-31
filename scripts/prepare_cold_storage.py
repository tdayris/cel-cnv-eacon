#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script aims to prepare the list of cold storage paths
for EaCoN cnv analysis
"""

import yaml

from argparse import ArgumentParser
from pathlib import Path


if __name__ == '__main__':
    main_parser = ArgumentParser(
        description="Prepare the cold_storage.yaml file for your Snakefile",
        epilog="Default path may not suit you... Set these variables!"
    )

    main_parser.add_argument(
        "path",
        help="Space separated list of paths to cold storage points",
        type=str,
        nargs="+"
    )

    main_parser.add_argument(
        "-o", "--output",
        help="Path to output file",
        type=str,
        default="cold_storage.yaml"
    )

    args = main_parser.parse_args()
    result = {
        "cold_storage": args.path
    }
    with open(args.output, "w") as outfile:
        data = yaml.dump(result, default_flow_style=False)
        outfile.write(data)
