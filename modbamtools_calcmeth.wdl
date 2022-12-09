version 1.0
workflow run_modbam_calcmeth {
    parameter_meta {
        haplotaggedBam: "Guppy with Remora reads aligned to assembly in BAM format and phased."
        sample_name: "Sample name. Will be used in output file."
        bed_file: "Bed file for calcmeth command"
        bed_file_name: "Name of bed file (Hs or CpG)"
    }
    
    input {
        File HAPLOTAGGEDBAM
        File HAPLOTAGGEDBAMBAI
        File BED_FILE
        String SAMPLE_NAME 
        String BED_FILE_NAME 
    }
    call modbam_calcmeth {
        input:
            haplotaggedBam = HAPLOTAGGEDBAM,
            haplotaggedBamBai = HAPLOTAGGEDBAMBAI,
            bed_file = BED_FILE,
            bed_file_name = BED_FILE_NAME,
            sample_name = SAMPLE_NAME
    }
output {
        File modbam_out = modbam_calcmeth.modbam_calcmeth_out
    }
}
task modbam_calcmeth {
    input {
        File haplotaggedBam
        File haplotaggedBamBai
        File bed_file
        String sample_name
        String bed_file_name
        Int memSizeGB = 128
        Int threadCount = 64
        Int diskSizeGB = 4 * round(size(haplotaggedBam, 'G')) + round(size(bed_file, 'G')) + 100
        String dockerImage = "meredith705/ont_methyl:latest" 
    }
    
    command <<<
        # exit when a command fails, fail with unset variables, print commands before execution
        set -eux -o pipefail
        set -o xtrace
        modbamtools calcMeth --bed ~{bed_file} \
            --hap \
            --out ~{sample_name}.~{bed_file_name}.bed \
            ~{haplotaggedBam}
    >>>
    
        output {
        File modbam_calcmeth_out= "~{sample_name}.~{bed_file_name}.bed"
    }
    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerImage
        preemptible: 2
    }
}