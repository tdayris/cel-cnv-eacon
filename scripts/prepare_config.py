#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script aims to prepare the yaml-formatted config file for
EaCoN cnv analysis
"""

import yaml

from argparse import ArgumentParser
from pathlib import Path


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


if __name__ == '__main__':
    main_parser = ArgumentParser(
        description="Prepare config.yaml file for your Snakefile",
        epilog="This script does not make any magic. Please check the prepared"
               " configuration file!",
    )

    main_parser.add_argument(
        "-r", "--rawdata",
        help="Path to raw data directory (default: %(default)s)",
        type=str,
        default="."
    )

    main_parser.add_argument(
        "-s", "--singularity",
        help="Name of the docker/singularity image (default: %(default)s)",
        type=str,
        default="docker://continuumio/miniconda3:4.4.10"
    )

    main_parser.add_argument(
        "--ldb",
        help="Path to ldb for supplementary analyses",
        type=str,
        default=None
    )

    main_parser.add_argument(
        "-w", "--workdir",
        help="Path to working directory (default: %(default)s)",
        type=str,
        default="."
    )

    main_parser.add_argument(
        "-t", "--threads",
        help="Maximum number of threads used (default: %(default)s)",
        type=int,
        default=1
    )

    main_parser.add_argument(
        "-d", "--design",
        help="Path to the design file (default: %(default)s)",
        type=str,
        default="design.tsv"
    )

    main_parser.add_argument(
        "--coldstorage",
        help="Path to cold storage mount points (default: %(default)s)",
        type=str,
        default="cold_storage.yaml"
    )

    main_parser.add_argument(
        "--segmenter",
        help="Name of the segmenter used to analyse profile"
             " (default: %(default)s)",
        type=str,
        default="ASCAT"
    )

    main_parser.add_argument(
        "--genome",
        help="The genome id (default: %(default)s)",
        type=str,
        default="hg19"
    )

    main_parser.add_argument(
        "--smooth_k",
        help="The half-window size for data smoothing "
             "(default depend on array type)",
        type=int,
        default=40
    )

    main_parser.add_argument(
        "--ser_pen",
        help="Penalty for the small events rescue step "
             "(default depend on array type)",
        type=int,
        default=0.5
    )

    main_parser.add_argument(
        "--nrf",
        help="Coefficient to multiply the L2R spread noise "
             "(default depend on array type)",
        type=float,
        default=0.9
    )

    main_parser.add_argument(
        "--penalty",
        help="Inverted penalty on new segment creation (50)",
        type=int,
        default=50
    )

    main_parser.add_argument(
        "--baf_filter",
        help="Perform a filtering of BAF noise "
             "(default depend on array type)",
        type=str,
        default="na33.r2"
    )

    args = main_parser.parse_args()
    config_params = {
        "segmenter": args.segmenter,
        "genome": args.genome,
        "ldb": args.ldb,
        "scripts": str(Path(__file__).parent),
        "penalty": args.penalty
    }

    if guess_array_type(Path(args.rawdata)) == "CytoScanHD_Array":
        config_params.update(**{
            "arraytype": "CytoScanHD_Array",
            "smooth_k": 5,
            "ser_pen": 20,
            "nrf": 1.0,
            "baf_filter": 0.75,
            "nar": "na33.r4"
        })
    else:
        config_params.update(**{
            "arraytype": "OncoScan_CNV",
            "smooth_k": "NULL",
            "ser_pen": 40,
            "nrf": 0.5,
            "baf_filter": 0.9,
            "nar": "na33.r2"
        })

    config = {
        "singularity_docker_image": args.singularity,
        "workdir": args.workdir,
        "threads": args.threads,
        "params": config_params,
        "design": args.design,
        "cold_storage": (
            args.coldstorage
            if isinstance(args.coldstorage, list)
            else [args.coldstorage]
        )
    }

    output_path = Path(args.workdir) / "config.yaml"
    with output_path.open("w") as config_yaml:
        data = yaml.dump(config, default_flow_style=False)
        config_yaml.write(data)
