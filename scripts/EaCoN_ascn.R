#!/bin/R

library("EaCoN");

EaCoN::ASCN.ff(
  RDS.file = snakemake@input[["rds"]],
  force = TRUE
);
