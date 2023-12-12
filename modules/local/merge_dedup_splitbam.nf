// Import generic module functions
include { initOptions; getSoftwareName; getOutputDir } from './functions'
include { isSingleFile } from './functions'

params.options = [:]
options        = initOptions(params.options)
directory      = getOutputDir('pairs_library')

ASSEMBLY_NAME = params['input'].genome.assembly_name // TODO: move to the parameters dictionary, and below:


process MERGE_DEDUP_SPLITBAM {
    tag "library:${library} run:${run}"
    label 'process_medium'
    publishDir "${directory}", mode: params.publish_dir_mode

    conda (params.enable_conda ? "bioconda::pairtools" : null)
//        if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
//            container "https://depot.galaxyproject.org/singularity/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        } else {
//            container "quay.io/biocontainers/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        }

    input:
    tuple val(library), file(run_pairsam)

    output:
    tuple val(library), 
        path("${library}.${ASSEMBLY_NAME}.nodups.pairs.gz"), emit: all_pairs

    tuple val(library), 
        path("${library}.${ASSEMBLY_NAME}.cis_11.pairs.gz"),
        path("${library}.${ASSEMBLY_NAME}.cis_22.pairs.gz"),
        path("${library}.${ASSEMBLY_NAME}.trans_12.pairs.gz"),
        path("${library}.${ASSEMBLY_NAME}.trans_21.pairs.gz"), emit: scs_pairs


    tuple val(library), 
        path("${library}.${ASSEMBLY_NAME}.nodups.pairs.gz.px2"),        
        path("${library}.${ASSEMBLY_NAME}.nodups.bam"),
        path("${library}.${ASSEMBLY_NAME}.dups.bam"),
        path("${library}.${ASSEMBLY_NAME}.unmapped.bam"),
        path("${library}.${ASSEMBLY_NAME}.unmapped.pairs.gz"),
        path("${library}.${ASSEMBLY_NAME}.dups.pairs.gz"), emit: extra

    tuple val(library), 
        path("${library}.${ASSEMBLY_NAME}.dedup.stats"), emit: stats

    path  "*.version.txt"         , emit: version


    script:
    def software = getSoftwareName(task.process)
    def merge_cmd = (
        isSingleFile(run_pairsam) ?
        "${params.decompress_cmd} ${run_pairsam}" :
        "pairtools merge ${run_pairsam} --nproc ${task.cpus} --tmpdir \$TASK_TMP_DIR"
    )

    """
    TASK_TMP_DIR=\$(mktemp -d -p ${task.distillerTmpDir} distiller.tmp.XXXXXXXXXX)

    ${merge_cmd} | pairtools dedup \
        --max-mismatch ${params.dedup.max_mismatch_bp} \
        --mark-dups \
        --output ${library}.${ASSEMBLY_NAME}.nodups.pairs.gz \
        --output-unmapped ${library}.${ASSEMBLY_NAME}.unmapped.pairs.gz \
        --output-dups ${library}.${ASSEMBLY_NAME}.dups.pairs.gz \
        --output-stats ${library}.${ASSEMBLY_NAME}.dedup.stats \
        | cat

    touch ${library}.${ASSEMBLY_NAME}.unmapped.bam
    touch ${library}.${ASSEMBLY_NAME}.nodups.bam
    touch ${library}.${ASSEMBLY_NAME}.dups.bam

    rm -rf \$TASK_TMP_DIR
    pairix ${library}.${ASSEMBLY_NAME}.nodups.pairs.gz

    bash ${baseDir}/bin/filter_single_experiment.sh \
        ${library}.${ASSEMBLY_NAME} \
        ./ \
        ${library}.${ASSEMBLY_NAME}.nodups.pairs.gz \
        ${params.parse.scs_min_mapq} \
        ${params.parse.scs_min_right_muts} \
        ${params.parse.scs_max_wrong_muts}

    pairtools --version > ${software}.version.txt

    """

}

