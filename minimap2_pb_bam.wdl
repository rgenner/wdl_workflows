version 1.0

workflow run_minimap2_for_bams {
    parameter_meta {
        unmapped_bam: "unmapped bam file with methylation information from ont or pb"
        ref: "Assembly (reference) to that reads are aligned to."
        sample_name: "Sample name. Will be used in output file."
        ref_name: "Reference name. Will be used in output file."
        mapMode: "data type - either ont or pb"
        
    }
    
    input {
        File unmapped_bam
        File unmapped_bam_bai
        File ref
        File ref_index
        String sample_name
        String ref_name    
        String extraArgs
        String mapMode
        Int memSizeGB = 128
		Int kmerSize = 17
        Int threads = 64
        Int diskSizeGB = 4 * round(size(unmapped_bam, 'G')) + round(size(ref, 'G')) + 100
        String dockerImage = "meredith705/ont_methyl:latest" 
    }


    call minimap2_ont_bam {
    	input:
        unmapped_bam = unmapped_bam,
        unmapped_bam_bai = unmapped_bam_bai,
        ref = ref,
        ref_index = ref_index,
        sample_name = sample_name,
        ref_name = ref_name,
        extraArgs = extraArgs,
        mapMode = mapMode
        memSizeGB = memSizeGB,
        kmerSize = kmerSize,
        threads = threads,
        diskSizeGB = diskSizeGB,
        dockerImage = dockerImage
    }


output {
        File minimap2_out = minimap2_ont_bam.minimap2_ont_bam_out
        File minimap2_idx_out = minimap2_ont_bam.minimap2_ont_bam_idx_out
    }
}

task minimap2_ont_bam {
  input {
    File unmapped_bam
    File unmapped_bam_bai
    File ref
    File ref_index
    String sample_name
    String ref_name
    String extraArgs
    String mapMode = "map-pb"
    Int memSizeGB = 128
	Int kmerSize = 17
    Int threads = 64
    Int diskSizeGB = 4 * round(size(unmapped_bam, 'G')) + round(size(ref, 'G')) + 100
    String dockerImage = "meredith705/ont_methyl:latest" 
  }
    
    command <<<
    set -o pipefail # return value of pipeline is the status of last command with non-zero status upon exit
    set -e # instructs shell to exit if a command fails
    set -u # treats unset variables as error when substituting
    set -o xtrace # prints out command arguments during execution
    
    samtools fastq -TMm,Ml ${unmapped_bam} | minimap2 -y -x ~{mapMode} -t 40 -a --eqx -k 17 -K 5G ~{ref} ~{unmapped_bam} | samtools view -@ 10 -bh - | samtools sort - > ~{sample_name}.hg38.mod.bam
    
    samtools index ~{sample_name}.hg38.mod.bam              

    >>>
    
        output {
        File minimap2_ont_bam_out = "~{sample_name}.hg38.mod.bam"
        File minimap2_ont_bam_idx_out = "~{sample_name}.hg38.mod.bam.bai"
    }


    runtime {
        memory: memSizeGB + " GB"
        cpu: threads
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerImage
        preemptible: 2
    }
}