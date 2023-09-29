def helpMessage() {
  log.info """\

 
                    8888888888888888   88888
                   88          88      88  88
                    8888       88      88888
                       88      88      88   88
                88888888       88      88    888888
 
                88  88  88   888    88888    888888
                88  88  88  88 88   88  88  88
                88 8888 88 88   88  88888    8888
                 888  888 888888888 88   88     88
                  88  88  88     88 88    8888888
 
    S T R - W A R S (Short Tandem Repeat Workflow Automation Research Suite)
    ========================================================================

        Usage:
        nextflow run viv3kanand/STR-WARS -r main --fastq 'fastq_pass' --fast5 'fast5_pass' --reference 'reference/ref.fa' --config 'reference/repeat_config.tsv'

        Testing pipeline:
        nextflow run viv3kanand/STR-WARS -r main -profile test

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
        """
        .stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

log.info """\
    F X N A N O - N F   P I P E L I N E
    ===================================
    reference    : ${params.reference}
    fastq        : ${params.fastq}
    fast5        : ${params.fast5}
    config       : ${params.config}
    outdir       : ${params.outdir}
    """
    .stripIndent(true)

/*
 * Merge fastq files by barcode
 */
process MERGE_FASTQ {
    tag "Merging $barcode"
    publishDir "$params.outdir/merged_fastq", mode:'copy'

    input:
    tuple val(barcode), path(reads)

    output:
    tuple val(barcode), path("${barcode}.fastq.gz")

    script:
    """
    cat ${reads.join(' ')} > ${barcode}.fastq.gz
    """
}

/*
 * Algin reads using Minimap2
 */
process ALIGN_MINIMAP {
    tag "Aligning for $barcode"
    publishDir "$params.outdir/minimap", mode:'copy'

    container 'quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:7e6194c85b2f194e301c71cdda1c002a754e8cc1-0'

    input:
    path reference
    tuple val(barcode), path(reads)

    output:
    tuple val(barcode), path("${barcode}.sam")

    script:
    """
    minimap2 -a -x map-ont -t 40 $reference $reads | samtools view -Sh -F 3844 - | samtools sort -o ${barcode}.sam -
    """
}

/*
 * Index fast5
 */
process INDEX_FAST5 {
    tag "Indexing Fast5"
    publishDir "$params.outdir/STRique/index", mode:'copy'

    container 'viv3kanand/strique_vbz'

    input:
    path fast5

    output:
    path "reads.fofn"

    script:
    """
    python3 /app/scripts/STRique.py index --out_prefix $PWD/fast5_pass --recursive $fast5 > reads.fofn
    """
}

/*
 * run STRique
 */
process STRIQUE {
    cpus = 10
    
    tag "Repeat quantification for $barcode"
    publishDir "$params.outdir/STRique/counts", mode:'copy'

    container 'viv3kanand/strique_vbz'
    
    input:
    path config
    path index
    tuple val(barcode), path(sam)

    output:
    path "${barcode}.strique.tsv"
    path "${barcode}.log"

    script:
    """
    cat $sam | python3 /app/scripts/STRique.py count --t ${task.cpus} $index /app/models/r9_4_450bps.model $config > ${barcode}.strique.tsv 2> ${barcode}.log
    """
}

workflow {
    // Collect the fastq files by barcode as tuple
    Channel
        .fromPath("$params.fastq/**/", checkIfExists: true)
        .map { file -> 
        def barcode = file.getName().replaceAll(/.*barcode(\d+).*/, 'barcode$1')
        tuple(barcode, file) }
        .groupTuple()
        .set { query_ch }
    // merge fastq files
    merge_fastq_ch = MERGE_FASTQ(query_ch)
    // align using minimap2
    align_ch = ALIGN_MINIMAP(params.reference, merge_fastq_ch)
    // fast5 index for STRique
    fast5_index_ch = INDEX_FAST5(params.fast5)
    // run STRique
    strique_ch = STRIQUE(params.config, fast5_index_ch, align_ch)
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! The results can be found in the following directory --> $params.outdir\n" : "Oops .. something went wrong" )
}