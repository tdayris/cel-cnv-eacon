"""
This rule performs normalisation, and some verifications
"""
rule EaCoN_process:
    input:
        unpack(EaCoN_in)
    output:
        qc = expand(
            op.join("{sample}", "{sample}_2.4.0_{nar}.{ext}"),
            sample="{sample}",
            nar=config["params"]["nar"],
            ext=paircheck_qc()
        ),
        qc2 = expand(
            op.join("{sample}", "{sample}_{ext}"),
            sample="{sample}",
            ext=plot_qc()
        ),
        rds = op.join(
            "{sample}",
            "{sample}_{}_{}_processed.RDS".format(
                config['params']['arraytype'],
                config['params']['genome'],
                sample="{sample}"
            )
        )
    message:
        "Processing {wildcards.sample} CEL file(s)"
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 5120)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 60, 240)
        )
    threads:
        1
    priority:
        30
    conda:
        "env/eacon_dependencies.yaml"
    wildcard_constraints:
        sample = r"[^/]+"
    log:
        "logs/EaCoN/{sample}_process.log"
    script:
        "../scripts/EaCoN_process.R"


"""
This rule performs segmentation
"""
rule EaCoN_segment:
    input:
        rds = os.path.join(
            "{sample}",
            "{}_{}_{}_processed.RDS".format(
                "{sample}",
                config['params']['arraytype'],
                config['params']['genome']
            )
        )
    output:
        files = expand(
            os.sep.join([
                "{sample}", config["params"]["segmenter"], "L2R",
                "{sample}.{ext}"
            ]),
            sample="{sample}",
            ext=["Cut.cbs", "NoCut.cbs", "Rorschach.png", "SegmentedBAF.txt"]
        ),
        seg_rds = os.sep.join([
            "{sample}", config["params"]["segmenter"], "L2R",
            f"{{sample}}.SEG.{config['params']['segmenter']}.RDS"
        ]),
        segment_png = report(
            os.sep.join([
                "{sample}", config["params"]["segmenter"], "L2R",
                f"{{sample}}.SEG.{config['params']['segmenter']}.png"
            ]),
            category="BAF and L2R",
            caption="../report/aspcf.rst"
        )
    message:
        "Segmentation of {wildcards.sample} normalized data"
    threads: 1
    conda:
        "env/eacon_dependencies.yaml"
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 5120)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 180)
        )
    log:
        "logs/EaCoN/{sample}_Segmentation.log"
    script:
        "../scripts/EaCoN_segment.R"


"""
This rule tries to build a copy number model
"""
rule EaCoN_ascn:
    input:
        rds = os.sep.join([
            "{sample}", config["params"]["segmenter"], "L2R",
            f"{{sample}}.SEG.{config['params']['segmenter']}.RDS"
        ])
    output:
        # directory(os.sep.join([
        #     "{sample}",
        #     config["params"]["segmenter"],
        #     "ASCN"
        # ]))
        gama_eval_png = report(
            os.sep.join(["{sample}", config["params"]["segmenter"],
                         "ASCN", "{sample}.gammaEval.png"]),
            category="ASCN Model",
            caption="../report/ascn.rst"
        ),
        gama_eval_txt = os.sep.join([
            "{sample}", config["params"]["segmenter"],
            "ASCN", "{sample}.gammaEval.txt"
        ])
    message:
        "Building copy number models for {wildcards.sample}"
    threads: 1
    conda:
        "env/eacon_dependencies.yaml"
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 3072, 5120)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 180)
        )
    log:
        "logs/EaCoN/{sample}_ascn.log"
    script:
        "../scripts/EaCoN_ascn.R"


"""
This rule writes a HTML report
"""
rule EaCoN_Annotate:
    input:
        rds = os.sep.join([
            "{sample}", config["params"]["segmenter"], "L2R",
            f"{{sample}}.SEG.{config['params']['segmenter']}.RDS"
        ])
    output:
        files = expand(
            os.sep.join([
                "{sample}", config["params"]["segmenter"],
                "L2R", "{sample}.{ext}"
            ]),
            sample="{sample}",
            ext=["BAF.png", "Cut.acbs", "Instab.txt", "INT.png",
                 "L2R.G.png", "L2R.K.png", "TargetGenes.txt",
                 "TruncatedGenes.txt"]
        ),
        chromosomes = expand(
            os.sep.join([
                "{sample}", config["params"]["segmenter"],
                "L2R", "chromosomes", "{chr}.png"
            ]),
            sample="{sample}",
            chr=[f"chr{i}" for i in list(map(str, range(1, 23))) + ["X", "Y"]]
        ),
        html = report(
            os.path.sep.join([
                "{sample}", config["params"]["segmenter"], "L2R",
                "{sample}.REPORT.html"
            ]),
            caption="../report/html.rst",
            category="HTML reports"
        ),
        genome_dir = directory(
            os.sep.join(["{sample}", config["params"]["segmenter"], "L2R",
                         f"{{sample}}_solo.{config['params']['genome']}"])
        )
    message:
        "Reporting data for {wildcards.sample}"
    threads: 1
    conda:
        "env/eacon_dependencies.yaml"
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 180)
        )
    log:
        "logs/EaCoN/{sample}_annotate.log"
    script:
        "../scripts/EaCoN_annotate.R"
