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
        # Copy/link cell files
        # cel = expand("raw_data/{sample}", sample=cel_link_dict.keys()),
        # EaCoN process
        # rds = expand(
        #     op.join(
        #         "{sample}",
        #         "{sample}_{}_{}_processed.RDS".format(
        #             config['params']['arraytype'],
        #             config['params']['genome'],
        #             sample="{sample}"
        #         )
        #     ),
        #     sample=design["Sample_id"]
        # ),
        # EaCoN Segment
        # seg_rds = expand(
        #     os.sep.join([
        #         "{sample}", config["params"]["segmenter"], "L2R",
        #         f"{{sample}}.SEG.{config['params']['segmenter']}.RDS"
        #     ]),
        #     sample=design["Sample_id"]
        # ),
        # EaCoN models
        ascn = expand(
            os.sep.join(["{sample}", config["params"]["segmenter"],
                         "ASCN", "{sample}.gammaEval.png"]),
            sample=design["Sample_id"]
        ),
        # EaCoN annotate
        html = expand(
            os.path.sep.join([
                "{sample}", config["params"]["segmenter"], "L2R",
                "{sample}.REPORT.html"
            ]),
            sample=design["Sample_id"]
        ),
        instability = expand(
            "{sample}/{sample}_GIS_from_best_gamma.txt",
            sample=design["Sample_id"]
        )
    message:
        "Finishing the EaCoN pipeline"
