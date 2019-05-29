#!/bin/R

library("EaCoN");
library("devtools");

Sys.setenv(
  PATH = paste(
    Sys.getenv("PATH"),
    snakemake@config[["params"]][["scripts"]],
    sep=":"
  )
);

EaCoN::Annotate.ff(
  RDS.file = snakemake@input[["rds"]],
  author.name = "STRonGR",
  ldb = snakemake@config[["params"]][["ldb"]],
  solo = TRUE
);
