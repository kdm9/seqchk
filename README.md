# seqchk

Quickly QC, map, taxonid, and check a new sequencing run.

This is basically a heavily-reduced version of
[Acanthophis](https://github.com/kdm9/acanthophis), designed for interactive
use when checking a new set of sequencing.

Using seqchk is a two-step process: first, use the `seqchk` command to generate
a workspace, then use snakemake to execute the generated workflow and produce
the report.

```
usage: seqchk [-h] --reference REFERENCE [--seed SEED] [--mash] [--subsample SUBSAMPLE] [--head HEAD] [--kraken-db KRAKEN_DB] [--workdir WORKDIR] fastqs [fastqs ...]

positional arguments:
  fastqs

options:
  -h, --help            show this help message and exit
  --reference REFERENCE, -r REFERENCE
                        Reference Genome
  --seed SEED, -S SEED  Random Seed for subsampling
  --mash, -m            Run mash?
  --subsample SUBSAMPLE, -s SUBSAMPLE
                        Number of reads to randomly subsample (0 to disable, which is the default)
  --head HEAD, -H HEAD  Number of reads take from head of file
  --kraken-db KRAKEN_DB, -k KRAKEN_DB
                        Run Kraken + Bracken, using this DB (give dir name)
  --workdir WORKDIR     Working dir
```

# Example

This is a recent example of ~100 Arabidopsis whole rosette metagenomes:

```
# Generate a workspace for all CGA*.fastq.gz in a recent sequencing run
seqchk \
  --kraken-db /shared/dbs/kraken2/PlusPFP/2024-01-12 \
  --subsample 1000000 \
  --reference Araport11.fasta \
  --workdir seqcheck.CGA \
  /shared/sra/2024-09_CGA/00_fastq/CGA*.fastq.gz 

cd seqcheck.CGA
snakemake --profile cluster-v8
```

