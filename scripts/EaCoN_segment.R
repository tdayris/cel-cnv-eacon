#!/bin/R

library("EaCoN");

smooth_k <- base::as.numeric(snakemake@config[["params"]][["smooth_k"]]);
if (is.null(snakemake@config[["params"]][["smooth_k"]])) {
  smooth_k <- NULL;
}

EaCoN::Segment.ff(
  RDS.file = snakemake@input[["rds"]],
  segmenter = snakemake@config[["params"]][["segmenter"]],
  smooth.k = smooth_k,
  BAF.filter = base::as.numeric(snakemake@config[["params"]][["baf_filter"]]),
  SER.pen = base::as.numeric(snakemake@config[["params"]][["ser_pen"]]),
  nrf = base::as.numeric(snakemake@config[["params"]][["nrf"]]),
  force = TRUE
);
