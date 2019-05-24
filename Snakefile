import sys              # System operations
import snakemake.utils  # Version control

# Python 3.7 is required
if sys.version_info < (3, 7):
    raise SystemError("Please use Python 3.7 or later.")

# Snakemake 5.4.2 at least is required.
snakemake.utils.min_version("5.4.2")

include: "rules/common.smk"
include: "rules/copy.smk"
include: "rules/eacon.smk"


workdir: config["workdir"]
singularity: config["singularity_docker_image"]
localrules: copy_cel

rule all:
    input:
        html = expand(
            os.path.sep.join([
                "{sample}", config["segmenter"], "L2R", "{sample}.REPORT.html"
            ]),
            sample=sample_id_list
        ),
        gamma_ascat = expand(
            os.sep.join([
                "{sample}",
                config["segmenter"],
                "ASCN"
            ]),
            sample=config["Sample_id"]
        )
    message:
        "Finishing the EaCoN pipeline"
