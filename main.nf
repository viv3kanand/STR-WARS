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


/*
* Algin reads using Minimap2
*/
process ALIGN_MINIMAP {
    tag "Aligning for $barcode"
    publishDir "$params.outdir/sam", mode:'copy'

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
    python3 /app/scripts/STRique.py index --recursive $fast5 > reads.fofn
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
    // align using minimap2
    align_ch = ALIGN_MINIMAP(params.reference, merge_fastq_ch)
    // fast5 index for STRique
    fast5_index_ch = INDEX_FAST5(params.fast5)
    // run STRique
}