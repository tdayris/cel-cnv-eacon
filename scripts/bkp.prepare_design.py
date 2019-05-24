#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
This file is part of STRonGR.

STRonGR is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

STRonGR is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
"""

import begin
import logging
import os
import pandas
import re
import traceback

from pathlib import Path


@begin.convert(cytodir=str)
def parse_cyto_dir(cytodir: "Path to a cytoscan dir.",
                   strongr: "Build design for STRonGR" = True,
                   guess_conditions: "Try to guess conditions" = True) \
                   -> pandas.DataFrame:
    """
    Build a design file from a cytoscan directory
    """
    cytodir = Path(cytodir)
    logging.debug("Path identified as: %s" % str(cytodir))
    sample = ("Sample_id" if strongr else "SampleName")
    cel = ("CEL" if strongr else "cel_files")
    samples = {}
    for content in cytodir.iterdir():
        if not content.is_file():
            continue

        if content.name.endswith(".CEL"):
            samples[content.name] = {
                sample: str(content.stem),
                cel: str(content.absolute())
            }

            if not guess_conditions:
                continue
            elif content.name.startswith("MR"):
                samples[content.name]["Project"] = "MatchR"
            elif content.name.startswith("M"):
                samples[content.name]["Project"] = "Moscato"
            elif content.name.startswith(("B", "L", "T")):
                samples[content.name]["Project"] = "Safir"
            else:
                samples[content.name]["Project"] = "Pathmol"

    data = pandas.DataFrame(samples).T
    try:
        return data[[sample, cel, "Project"]]
    except KeyError:
        return data


@begin.convert(oncodir=str)
def parse_onco_dir(oncodir: "Path to a oncoscan dir.",
                   strongr: "Build design for STRonGR" = True,
                   guess_conditions: "Try to guess conditions" = True) \
                   -> pandas.DataFrame:
    """
    Build a design file from a cytoscan directory
    """
    oncodir = Path(oncodir)
    logging.debug("Path identified as: %s" % str(oncodir))
    sample = ("Sample_id" if strongr else "SampleName")
    at = "ATChannelCel"
    cg = "GCChannelCel"
    samples = {}
    for content in oncodir.iterdir():
        if not content.is_file():
            continue

        if content.name.endswith("A.CEL"):
            samples[content.name] = {
                sample: str(content.stem)[:-2],
                at: str(content.absolute()),
                cg: str(content.absolute()).replace(
                    "A.CEL", "C.CEL"
                ),
            }

            if not guess_conditions:
                continue
            elif content.name.startswith("MR"):
                samples[content.name]["Project"] = "MatchR"
            elif content.name.startswith("M"):
                samples[content.name]["Project"] = "Moscato"
            elif content.name.startswith(("B", "L", "T")):
                samples[content.name]["Project"] = "Safir"
            else:
                samples[content.name]["Project"] = "Pathmol"

    data = pandas.DataFrame(samples).T
    try:
        return data[[sample, at, cg, "Project"]]
    except KeyError:
        return data


@begin.convert(name=str)
def clean_name(name: "Name of a sample") -> str:
    """
    Clean a name in order to try to extract conditions from a sample name.
    """
    if any(i in name for i in ["102", "103"]):
        print(name)
    # Remove extentions
    name = ".".join([
        i
        for i in name.split(".")
        if i not in ("R1", "R2", "fastq", "gz")
    ])
    if any(i in name for i in ["102", "103"]):
        print(name)

    # Remove sample id, which is usually at the beginning
    if any(i in name for i in ["102", "103"]):
        print(name.split("_")[1:])
    return name.split("_")[1:]


@begin.convert(fqdir=str)
def parse_fastq_dir_single(
        fqdir: "Path to a fastq repository",
        guess_conditions: "Try to guess conditions" = False) \
        -> pandas.DataFrame:
    """
    Buil a design file from a fastq project repository
    """
    fq_regex = "^.*f(ast)?q(.gz)?$"
    fqdir = Path(fqdir)
    logging.debug("Path identified as: %s" % str(fqdir.absolute()))
    fq_files = [
        content
        for content in fqdir.iterdir()
        if not (content.is_dir() or re.match(fq_regex, content.name) is None)
        # We do not care about directories
        # We do not care about non-fastq files
    ]

    # Here, we make the following hypothesis:
    # 1: fastq pairs have a name so close, thant sorting samples alphabetically
    #    will make them appear next to each other.
    # 2: first in pairs reads are the ones in which the number 1 apprears at
    #    most in their name ; so they will appear at first in the list when
    #    sorted alphabetically.
    samples = {
        i.stem: {
            "Sample_id": i.stem,
            "Upstream_file": i
        }
        for i in sorted(fq_files)
    }

    if guess_conditions:
        for i in samples.keys():
            for idx, cond in enumerate(clean_name(i)):
                samples[i]["Condition_%i" % idx] = cond

    data = pandas.DataFrame.from_dict(samples, orient="index").fillna("Empty")
    for col in data.columns.tolist():
        if len(data[col].unique()) == 1:
            del data[col]
    return data


@begin.convert(fqdir=str)
def parse_fastq_dir_pair(fqdir: "Path to a fastq repository",
                         guess_conditions: "Try to guess conditions" = False) \
                         -> pandas.DataFrame:
    """
    Buil a design file from a fastq project repository
    """
    fq_regex = "^.*f(ast)?q(.gz)?$"
    fqdir = Path(fqdir)
    logging.debug("Path identified as: %s" % str(fqdir.absolute()))
    fq_files = [
        content
        for content in fqdir.iterdir()
        if not (content.is_dir() or re.match(fq_regex, content.name) is None)
        # We do not care about directories
        # We do not care about non-fastq files
    ]

    # Here, we make the following hypothesis:
    # 1: fastq pairs have a name so close, thant sorting samples alphabetically
    #    will make them appear next to each other.
    # 2: first in pairs reads are the ones in which the number 1 apprears at
    #    most in their name ; so they will appear at first in the list when
    #    sorted alphabetically.
    fq_files = sorted(fq_files)
    samples = {
        i.stem: {
            "Sample_id": os.path.commonprefix([i.stem, j.stem]).strip("_"),
            "Upstream_file": i,
            "Downstream_file": j
        }
        for i, j in zip(fq_files[::2], fq_files[1::2])
    }

    if guess_conditions:
        for i in samples.keys():
            for idx, cond in enumerate(clean_name(i)):
                samples[i]["Condition_%i" % idx] = cond

    data = pandas.DataFrame.from_dict(samples, orient="index").fillna("Empty")
    for col in data.columns.tolist():
        if len(data[col].unique()) == 1:
            del data[col]
    return data


@begin.start
@begin.logging
@begin.tracebacks
@begin.convert(workdir=str, design=str, cytoscan=begin.utils.tobool,
               strongr=begin.utils.tobool, oncoscan=begin.utils.tobool,
               fastq=begin.utils.tobool, guess_conditions=begin.utils.tobool)
def main(workdir: "Path to the working directory" = ".",
         design: "Path to output file" = "Design.tsv",
         cytoscan: "Cytoscan analysis preparation" = False,
         oncoscan: "Oncoscan analysis preparation" = False,
         strongr: "Build design for STRonGR" = False,
         guess_conditions: "Try to guess conditions" = False,
         fastq_single: "Prepare analysis from Fastq single" = False,
         fastq_pair: "Prepare analysis from Fastq paired" = False) -> None:
    """
    This script intends to create design file from Cytoscan/Oncoscan
    repositories, as expected by STRonGR.

    WARNING: Fastq condition guess is nt fuctionnal.
    """
    if os.path.exists(design):
        raise FileExistsError("Output file already exists (%s)" % design)

    data = None
    if cytoscan:
        logging.debug("Parsing directory for CEL files (CytoScan mode)")
        data = parse_cyto_dir(workdir, strongr, guess_conditions)
    elif oncoscan:
        logging.debug("Parsing directory for CEL files (OncoScan mode)")
        data = parse_onco_dir(workdir, strongr, guess_conditions)
    elif fastq_single:
        logging.debug("Parsing directory for Fastq files (single-end mode)")
        data = parse_fastq_dir_single(workdir, guess_conditions)
    elif fastq_pair:
        logging.debug("Parsing directory for Fastq files (paired mode)")
        data = parse_fastq_dir_pair(workdir, guess_conditions)
    else:
        raise ValueError("Please select a preparation mode (Onco, Cyto, ...)")

    data.to_csv(design, sep="\t", index=False)
