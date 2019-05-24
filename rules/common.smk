"""
While other .smk files contains rules and pure snakemake instructions, this
one gathers all the python instructions surch as config mappings or input
validations.
"""

import os.path as op
import pandas as pd

from typing import Dict, List

# Git prefix
git = "https://bitbucket.org/tdayris/snakemake-wrappers/raw"

# Loading configuration
configfile: "config.yaml"
validate(config, schema="../schemas/config.schema.yaml")

# Loading design file
design = pd.read_csv(
    config["design"],
    sep="\t",
    header=0,
    index_col=None
)
design.set_index(design["Sample_id"])
validate(design, schema="../schemas/design.schema.yaml")


def is_cytoscan() -> bool:
    """
    Return true if analysis is Cytoscan
    """
    return "ATChannelCel" in design.columns.tolist()


def EaCoN_in(wildcards) -> Dict[str, str]:
    """
    This function returns the correct couple of samples
    """
    if is_cyto_bool is True:
        return {
            "ATChannelCel": f"{wildcards.sample}_A.CEL",
            "GCChannelCel": f"{wildcards.sample}_C.CEL
        }
    return {
        "CEL": f"{wildcards.sample}.CEL"
    }


def cel_link() -> Dict[str, str]:
    """
    This function links the samples and their filename just like:
    sample file name : sample path
    """
    # Will cause KeyError on single stranded Cytoscan analysis
    # Better ask forgiveness than permission !
    try:
        # Cytoscan case
        cel_list = chain(design["ATChannelCel"], design["GCChannelCel"])
    except KeyError:
        # Oncoscan case
        cel_list = design["CEL"]
    finally:
        return {
            op.basename(cel): op.realpath(cel)
            for cel in cel_list
        }


def paircheck_qc() -> List[str]:
    """
    Return several file extensions related to Cytoscan/Oncoscan
    """
    if is_cyto_bool is True:
        return ["qc.txt", "log", "paircheck.txt"]
    return ["qc.txt", "log"]


def plot_qc() -> List[str]:
    """
    Return several file extensions related to Cytoscan/Oncoscan
    """
    if is_cyto_bool is True:
        return [
            "pairs.txt",
            f"{config['arraytype']}_{config['genome']}_rawplot.png"
        ]
    return ["CELfile.txt"]


def sample_id() -> List[str]:
    """
    Return the list of sample identifiers
    """
    return design["Sample_id"].tolist()


# Instanciate variables
cel_link_dict = cel_link()
is_cyto_bool = is_cytoscan()
sample_id_list = sample_id()
