# Nextflow VCF Processing Pipeline

This repository contains a Nextflow pipeline for processing VCF files. The pipeline filters SNPs, updates sample IDs, extracts a single sample, annotates the file with ANNOVAR, generates a GDS file, and creates group files for GMMAT analysis.

## Table of Contents
- [Overview](#overview)
- [Pipeline Steps](#pipeline-steps)
- [Dependencies](#dependencies)
- [Setup](#setup)
- [Usage](#usage)
- [Input Files](#input-files)
- [Output Files](#output-files)
- [License](#license)

## Overview

This pipeline is implemented using [Nextflow](https://www.nextflow.io/), allowing reproducible and scalable VCF processing. Each step of the pipeline is modular, ensuring flexibility and efficient processing across multiple stages.

## Pipeline Steps

1. **Load BCFTOOLS Module**: Prepares BCFTOOLS for subsequent processing steps.
2. **Filter SNPs and Participants**: Filters SNPs based on R2 and MAF values and retains specified participants.
3. **Update IID**: Updates sample IDs in the VCF file.
4. **Extract One Sample**: Extracts a specific sample from the VCF file.
5. **Annotate with ANNOVAR**: Annotates the VCF file with ANNOVAR using the refGene database.
6. **Create GDS File**: Converts the VCF file into a GDS file using an R script.
7. **Create Group Files**: Generates group files for GMMAT analysis and modifies the output to remove 'chr' prefixes.

## Dependencies

The following software and tools are required to run the pipeline:
- [Nextflow](https://www.nextflow.io/) (DSL2)
- [BCFTOOLS](http://samtools.github.io/bcftools/) v1.18 or later
- [Plink](https://www.cog-genomics.org/plink/) v1.9 or later
- [ANNOVAR](https://annovar.openbioinformatics.org/) (ensure `table_annovar.pl` is available in your path)
- [R](https://www.r-project.org/) v4.2 or later

Make sure these tools are accessible in your system path or configure module loading if using a cluster environment.

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/vcf-processing-pipeline.git
   cd vcf-processing-pipeline
