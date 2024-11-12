#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Step 1: Load BCFTOOLS Module
process LoadBCFTools {
    script:
    """
    module load BCFTOOLS
    """
}

// Step 2: Filter SNPs based on R2 and MAF criteria and keep only specified participants
process FilterSNPs {
    input:
    file input_vcf from "CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_fromPlink.vcf.gz"
    file samples_list from "list_part_to_keep.txt"
    
    output:
    file "CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_11469Part.vcf.gz" into filtered_vcf

    script:
    """
    // Filter VCF file to keep only participants specified in 'list_part_to_keep.txt'
    bcftools view -S ${samples_list} -Oz -o CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_11469Part.vcf.gz ${input_vcf}
    """
}

// Step 3: Update IID (Sample IDs) in the VCF file
process UpdateIID {
    input:
    file filtered_vcf
    file update_ids from "update_samples_id.txt"
    
    output:
    file "CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_fromPlink_UpdatedIID.vcf.gz" into updated_vcf

    script:
    """
    // Update sample IDs in the VCF file using the 'update_samples_id.txt' list
    bcftools reheader -s ${update_ids} -o CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_fromPlink_UpdatedIID.vcf.gz ${filtered_vcf}
    """
}

// Step 4: Extract a single sample based on the specified list in 'sample.txt'
process ExtractOneSample {
    input:
    file updated_vcf
    file sample_file from "sample.txt"
    
    output:
    file "CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_11469Part_OneSample.vcf" into one_sample_vcf

    script:
    """
    module load Plink/1.9.10
    module load BCFTOOLS/1.18
    // Extract a single sample from the updated VCF file
    bcftools view -S ${sample_file} --force-samples ${updated_vcf} -o CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_11469Part_OneSample.vcf -O v
    """
}

// Step 5: Annotate the VCF file using ANNOVAR for functional genomic annotation
process AnnotateWithANNOVAR {
    input:
    file one_sample_vcf
    
    output:
    file "CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_11469Part_OneSample_Annotated.hg38_multianno.txt" into annotated_file

    script:
    """
    module load Annovar
    // Run ANNOVAR to annotate the VCF file with refGene database
    /mnt/mfs/cluster/bin/ANNOVAR/annovar_201804/table_annovar.pl \
    ${one_sample_vcf} \
    /mnt/mfs/cluster/bin/ANNOVAR/annovar_201804/humandb \
    -buildver hg38 \
    -out CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_11469Part_OneSample_Annotated \
    -remove \
    -protocol refGene \
    -operation g \
    -nastring . \
    -vcfinput
    """
}

// Step 6: Create a GDS (Genomic Data Structure) file from the VCF file using an R script
process CreateGDS {
    input:
    file updated_vcf
    
    output:
    file "CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_fromPlink_UpdatedIID.gds" into gds_file

    script:
    """
    // Generate a GDS file for further analysis using a custom R script
    /mnt/mfs/cluster/bin/R-4.2.2.10/bin/Rscript ./MakeGDS.R -v ${updated_vcf} -o CU-TABLE-MHAS-PERU_chr21_fixed_filtR2.80.MaxAF0.01_fromPlink_UpdatedIID
    """
}

// Step 7: Create group files for GMMAT analysis and edit output to remove 'chr' prefixes
process CreateGroupFiles {
    input:
    file annotated_file
    
    output:
    file "CHR21_gmmat_groups_RSQ80_edited.txt"

    script:
    """
    mkdir -p output_script4
    cd output_script4
    // Create group files for GMMAT analysis using annotated file
    ./create_group_gmmat -a ../${annotated_file} -o CHR21_gmmat_groups_RSQ80.txt
    // Remove 'chr' prefix from group file to match analysis requirements
    sed 's/chr//g' CHR21_gmmat_groups_RSQ80.txt > CHR21_gmmat_groups_RSQ80_edited.txt
    cd ..
    """
}

// Workflow: Orchestrate all steps in the pipeline
workflow {
    LoadBCFTools() // Load required BCFTOOLS module
    FilterSNPs()   // Filter SNPs and participants
    UpdateIID(filtered_vcf)  // Update sample IDs
    ExtractOneSample(updated_vcf)  // Extract a single sample
    AnnotateWithANNOVAR(one_sample_vcf) // Annotate VCF file
    CreateGDS(updated_vcf) // Generate GDS file
    CreateGroupFiles(annotated_file) // Generate and modify group files
}
