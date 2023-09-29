## S T R - W A R S (Short Tandem Repeat Workflow Automation Research Suite)

        Usage:
        nextflow run viv3kanand/STR-WARS --fastq 'fastq_pass' --fast5 'fast5_pass' --reference 'reference/ref.fa' --config 'reference/repeat_config.tsv'

        Mandatory arguments:
         --fastq                        fastq directory (default ./fastq_pass)
         --fast5                        fast5 directory (default ./fast5_pass)
         --reference                    reference fasta (default ./reference/ref.fa)
         --config                       repeat config file (default ./reference/repeat_config.tsv)

       Optional arguments:
        --outdir                       Output directory (default ./results)
        --max_cpus                     Maximum number of CPUs that can be requested for any single job (default --max_cpus 10)
        --max_memory                   Maximum amount of memory that can be requested for any single job (default --max_memory '8.GB')
        --help                         Help message