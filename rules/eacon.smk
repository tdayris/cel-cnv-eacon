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
            nar=config["nar"],
            ext=paircheck_qc()
        ),
        qc2 = expand(
            op.join("{sample}", "{sample}_{ext}"),
            sample="{sample}",
            ext=plot_qc()
        ),
        rds = op.join(
            "{sample}",
            f"{config['arraytype']}_{config['genome']}_processed.RDS"
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
    wildcard_constraints:
        sample = r"[^/]+"
    log:
        "logs/EaCoN/{sample}_process.log"
    shell:
        (
            " R -e 'library(\"EaCoN\");"  # Loading EaCoN
            " EaCoN::OS.Process( "  # Function
            " ATChannelCel =  \"{input.ATChannelCel}\","  # _A.CEL
            " GCChannelCel = \"{input.GCChannelCel}\","  # _C.CEL
            " samplename = \"{wildcards.sample}\","  # Sample name
            " force = TRUE);'"  # Force overwrite
            " > {log}"  # Stdout redirection
            " 2>&1"  # Stderr redirection
        ) if is_cyto_bool is True else (
            " R -e 'library(\"EaCoN\");"  # Loading EaCoN
            " EaCoN::CS.Process( "  # Function
            " CEL = \"{input.CEL}\","  # CEL file
            " samplename = \"{wildcards.sample}\","  # Sample name
            " force = TRUE);'"  # Force overwrite
            " > {log}"  # Stdout redirection
            " 2>&1"  # Stderr redirection
        )

"""
This rule performs segmentation
"""
rule EaCoN_segment:
    input:
        rds = os.path.join(
            "{sample}",
            "{sample}"
            f"_{config['arraytype']}_{config['genome']}_processed.RDS"
        )
    output:
        files = expand(
            os.sep.join([
                "{sample}", config["segmenter"], "L2R",
                "{sample}.{ext}"
            ]),
            sample="{sample}",
            ext=["Cut.cbs", "NoCut.cbs", "Rorschach.png",
                 f"SEG.{config['segmenter']}.png", "SegmentedBAF.txt"]
        ),
        seg_rds = os.sep.join([
            "{sample}", config["segmenter"], "L2R",
            f"{{sample}}.SEG.{config['segmenter']}.RDS"
        ])
    message:
        "Segmentation of {wildcards.sample} normalized data"
    threads: 1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 5120)
        )
    log:
        f"logs/EaCoN/{sample}_Segmentation"
    shell:
        " R -e 'library(\"EaCoN\");"  # Loading EaCoN
        " EaCoN::Segment.ff("  # Function
        " RDS.file = \"{input.rds}\","  # Path to RDS file
        " segmenter = \"{config[segmenter]}\","  # Segmenter type
        " smooth.k = {config[smooth_k]},"  # half-window size (data smoothing)
        " BAF.filter = {config[baf_filter]},"  # filtering of BAF noise
        " SER.pen = {config[ser_pen]},"  # Penalty for the small events rescue
        " nrf = {config[nrf]},"  # L2R spread noise
        " force = TRUE);'"  # Force overwrite
        " > {log.out}"  # Stdout redirection
        " 2> {log.err}"  # Stderr redirection


"""
This rule tries to build a copy number model
"""
rule EaCoN_ascn:
    input:
        os.sep.join([
            "{sample}", config["segmenter"], "L2R",
            f"{{sample}}.SEG.{config['segmenter']}.RDS"
        ])
    output:
        directory(os.sep.join([
            "{sample}",
            config["segmenter"],
            "ASCN"
        ]))
    message:
        "Building copy number models for {wildcards.sample}"
    threads: 1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 3072, 5120)
        )
    log:
        out = os.path.join(config["log_directory"], "{sample}_CopyNumber.out"),
        err = os.path.join(config["log_directory"], "{sample}_CopyNumber.err")
    shell:
        " R -e 'library(\"EaCoN\");"  # Loading EaCoN
        " EaCoN::ASCN.ff("  # Function
        " RDS.file = \"{input}\","  # Path to RDS
        " force = TRUE);'"  # Force overwrite
        " > {log.out}"  # Stdout redirection
        " 2> {log.err}"  # Stderr redirection


"""
This rule writes a HTML report
"""
rule EaCoN_Annotate:
    input:
        rds = os.sep.join([
            "{sample}", config["segmenter"], "L2R",
            f"{{sample}}.SEG.{config['segmenter']}.RDS"
        ])
    output:
        files = expand(
            os.sep.join([
                "{sample}", config["segmenter"], "L2R", "{sample}.{ext}"
            ]),
            sample="{sample}",
            ext=["BAF.png", "Cut.acbs", "Instab.txt", "INT.png",
                 "L2R.G.png", "L2R.K.png", "TargetGenes.txt",
                 "TruncatedGenes.txt"]
        ),
        chromosomes = expand(
            os.sep.join([
                "{sample}", config["segmenter"],
                "L2R", "chromosomes", "{chr}.png"
            ]),
            sample="{sample}",
            chr=[f"chr{i}" for i in list(map(str, range(1, 23))) + ["X", "Y"]]
        ),
        html = report(
            os.path.sep.join([
                "{sample}", config["segmenter"], "L2R", "{sample}.REPORT.html"
            ]),
            caption="../report/html.rst",
            category="HTML reports"
        )
    message:
        "Reporting data for {wildcards.sample}"
    threads: 1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 5120)
        )
    log:
        out = os.path.join(config["log_directory"], "{sample}_Annotation.out"),
        err = os.path.join(config["log_directory"], "{sample}_Annotation.err")
    shell:
        "{config[module][EaCoN_]}"  # Module loading
        " export PATH=${{PATH}}:{config[scripts]} &&"  # Get grd
        " R -e 'library(\"EaCoN\");"  # Loading EaCoN
        " EaCoN::Annotate.ff("  # Functio
        " RDS.file = \"{input.rds}\","  # Path to RDSn
        " author.name = \"STRonGR: EaCoN 3.3\","  # Author name
        " ldb = \"{config[ldb]}\","  # Path to ldb
        " solo = TRUE);'"
        " > {log.out}"   # Stdout redirection
        " 2> {log.err}"  # Stderr redirection
