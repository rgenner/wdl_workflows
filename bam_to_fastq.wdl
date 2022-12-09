version 1.0

workflow run_bam_to_fastq {
    parameter_meta {
        unmapped_bam: "unmapped bam file with methylation information from ont or pb"
        sample_name: "Sample name. Will be used in output file."   
    }
    
    input {
        File unmapped_bam
        File unmapped_bam_bai
        String sample_name
        Int memSizeGB = 128
        Int threads = 64
        Int diskSizeGB = 4 * round(size(unmapped_bam, 'G'))
        String dockerImage = "meredith705/ont_methyl:latest" 
    }


    call bam_to_fastq {
    	input:
        unmapped_bam = unmapped_bam,
        unmapped_bam_bai = unmapped_bam_bai,
        sample_name = sample_name,
    }


output {
        File fastq_out = bam_to_fastq.bam_to_fastq_out
    }
}

task bam_to_fastq {
  input {
    File unmapped_bam
    File unmapped_bam_bai
    String sample_name
    Int memSizeGB = 128
    Int threads = 64
    Int diskSizeGB = 4 * round(size(unmapped_bam, 'G')) 
    String dockerImage = "meredith705/ont_methyl:latest" 
  }
    
    command <<<
    set -o pipefail # return value of pipeline is the status of last command with non-zero status upon exit
    set -e # instructs shell to exit if a command fails
    set -u # treats unset variables as error when substituting
    set -o xtrace # prints out command arguments during execution
    
    samtools fastq -TMm,Ml ~{unmapped_bam}           

    >>>
    
        output {
        File bam_to_fastq_out = "~{sample_name}.fastq"
    }


    runtime {
        memory: memSizeGB + " GB"
        cpu: threads
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerImage
        preemptible: 2
    }
}