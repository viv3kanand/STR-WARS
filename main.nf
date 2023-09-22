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



workflow {
    // Collect the fastq files by barcode as tuple
    def barcode_fastq_ch = Channel
        .fromPath("$params.fastq/**/")
        .flatMap { file ->
            def barcode = file.getName().replaceAll(/.*barcode(\d+).*/, 'barcode$1')
            def files = file.findAll {it.name.endsWith('.fastq.gz') }
            files.collect {tuple(barcode, it.toAbsolutePath() )}
        }.groupTuple()
    // merge fastq files
    // index reference
    // align using minimap2
    // fast5 index for STRique
    // run STRique
}