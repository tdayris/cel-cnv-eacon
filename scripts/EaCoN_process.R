#!/bin/R

library("EaCoN");

if ("ATChannelCel" %in% names(snakemake@input)) {
  EaCoN::OS.Process(
    ATChannelCel = snakemake@input[["ATChannelCel"]],
    GCChannelCel = snakemake@input[["GCChannelCel"]],
    samplename = snakemake@wildcards[["sample"]],
    apt.build = snakemake@config[["params"]][["nar"]],
    force = TRUE
  );
} else {
  EaCoN::CS.Process(
    CEL = snakemake@input[["CEL"]],
    samplename = snakemake@wildcards[["sample"]],
    force = TRUE
  );
}
