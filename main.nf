/*
 * pipeline input parameters
 */
params.fastq = "$projectDir/fastq"
params.fast5 = "$projectDir/fast5"
params.reference = "$projectDir/reference/ref.fa"
params.config = "$projectDir/reference/repeat_config.tsv"
params.outdir = "$projectDir/results"

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

workflow {
    // Collect the fastq files by barcode as tuple
    Channel
        .fromPath( "$params.fastq/**/" )
        .map { file -> 
        def barcode = file.getName().replaceAll(/.*barcode(\d+).*/, 'barcode$1')
        tuple(barcode, file) }
        .groupTuple()
        .set { query_ch }
    // merge fastq files
    merge_fastq_ch = MERGE_FASTQ(query_ch)
    // index reference
    // align using minimap2
    // fast5 index for STRique
    // run STRique
}