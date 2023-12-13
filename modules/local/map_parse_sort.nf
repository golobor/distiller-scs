// Import generic module functions
include { initOptions; getSoftwareName; getOutputDir } from './functions'

params.options = [:]
options        = initOptions(params.options)
directory      = getOutputDir('mapped_parsed_sorted_chunks')

ASSEMBLY_NAME = params['input'].genome.assembly_name // TODO: move to the parameters dictionary, and below:

process map_parse_sort_chunk_scs{
    tag "library:${library} run:${run}"
    label 'process_low'
    publishDir "${directory}", mode: params.publish_dir_mode

    conda (params.enable_conda ? "bioconda::sra-tools>=2.8.1 bioconda::pbgzip" : null)
//        if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
//            container "https://depot.galaxyproject.org/singularity/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        } else {
//            container "quay.io/biocontainers/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        }

    input:
    tuple val(library), val(run), val(chunk), file(fastq1), file(fastq2)
    tuple val(bwa_index_base), file(bwa_index_files)
    file(chrom_sizes)

    output:
    tuple val(library), val(run), val(chunk),
        path("${library}.${run}.${ASSEMBLY_NAME}.${chunk}.pairsam.${params.suffix}"),
        path("${library}.${run}.${ASSEMBLY_NAME}.${chunk}.bam"), emit: output
    path  "*.version.txt"         , emit: version


    script:
    def software = getSoftwareName(task.process)

    def mapping_options = params['map'].getOrDefault('mapping_options','')
    def trim_options = params['map'].getOrDefault('trim_options','')

    def dropreadid_flag = params['parse'].getOrDefault('drop_readid','false').toBoolean() ? '--drop-readid' : ''
    def keep_unparsed_bams_cmd = (
        params['parse'].getOrDefault('keep_unparsed_bams','false').toBoolean() ?
        "| tee >(samtools view -bS > ${library}.${run}.${ASSEMBLY_NAME}.${chunk}.bam)" : "" )
    def parsing_options = params['parse'].getOrDefault('parsing_options','')
    def bwa_threads = (task.cpus as int)
    def sorting_threads = (task.cpus as int)

    def mapping_cmd = (
        trim_options ?
        "fastp ${trim_options} \
        --json ${library}.${run}.${ASSEMBLY_NAME}.${chunk}.fastp.json \
        --html ${library}.${run}.${ASSEMBLY_NAME}.${chunk}.fastp.html \
        -i ${fastq1} -I ${fastq2} --stdout | \
        bwa mem -p -t ${bwa_threads} ${mapping_options} -SP ${bwa_index_base} \
        - ${keep_unparsed_bams_cmd}" : \
        \
        "bwa mem -t ${bwa_threads} ${mapping_options} -SP ${bwa_index_base} \
        ${fastq1} ${fastq2} ${keep_unparsed_bams_cmd}"
        )


    """
    TASK_TMP_DIR=\$(mktemp -d -p ${task.distillerTmpDir} distiller.tmp.XXXXXXXXXX)
    touch ${library}.${run}.${ASSEMBLY_NAME}.${chunk}.bam

    ${mapping_cmd} \
    | pairtools parse ${dropreadid_flag}  \
      ${parsing_options} \
      -c ${chrom_sizes} \
      | pairtools sort --nproc ${sorting_threads} \
                     --tmpdir \$TASK_TMP_DIR \
      | python ${baseDir}/bin/detect_s4t_mutations.py --chunksize 5000000 --drop-sam \
        -o ${library}.${run}.${ASSEMBLY_NAME}.${chunk}.pairsam.${params.suffix} - \
      | cat


    rm -rf \$TASK_TMP_DIR

    #bwa 2>&1 | head -n 3 | tail -n 1 &> ${software}.version.txt # TODO: fix error message
    pairtools --version >> ${software}.version.txt
    """
}

