// Import generic module functions
include { initOptions; getSoftwareName; getOutputDir } from './functions'

params.options = [:]
options        = initOptions(params.options)
directory      = getOutputDir('coolers_library')

MIN_RES = params['bin'].resolutions.collect { it as int }.min() // TODO: move to parameters dictionary
ASSEMBLY_NAME = params['input'].genome.assembly_name // TODO: move to the parameters dictionary

process bin_zoom {
    tag "library:${library} filter:${filter_name}"
    label 'process_high'
    publishDir "${directory}", mode: params.publish_dir_mode

    conda (params.enable_conda ? "bioconda::cooler" : null)
//        if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
//            container "https://depot.galaxyproject.org/singularity/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        } else {
//            container "quay.io/biocontainers/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        }

    input:
    tuple val(filter_name), val(filter_expr)
    tuple val(library), file(pairs_lib)
    file(chrom_sizes)

    output:
    tuple val(library), val(filter_name),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cool"), emit: cools

    tuple val(library), val(filter_name),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.mcool"), emit: mcools
    path  "*.version.txt"         , emit: version


    script:
    def software = getSoftwareName(task.process)

    def res_str = params['bin'].resolutions.join(',')
    // get any additional balancing options, if provided
    def balance_options = params['bin'].get('balance_options','')
    balance_options = ( balance_options ? "--balance-args \"${balance_options}\"": "")
    // balancing flag if it's requested
    def balance_flag = ( params['bin'].get('balance','true').toBoolean() ? "--balance ${balance_options}" : " " )
    def filter_cmd = (filter_expr == '' ? '' : "| pairtools select '${filter_expr}'")

    """
    ${params.pairsgz_decompress_cmd} ${pairs_lib} ${filter_cmd} | cooler cload pairs \
        -c1 2 -p1 3 -c2 4 -p2 5 \
        --assembly ${ASSEMBLY_NAME} \
        ${chrom_sizes}:${MIN_RES} - ${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cool

    cooler zoomify \
        --nproc ${task.cpus} \
        --out ${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.mcool \
        --resolutions ${res_str} \
        ${balance_flag} \
        ${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cool

    cooler --version > ${software}.version.txt
    """
}


process bin_zoom_scs {
    tag "library:${library} filter:${filter_name}"
    label 'process_high'
    publishDir "${directory}", mode: params.publish_dir_mode

    conda (params.enable_conda ? "bioconda::cooler" : null)
//        if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
//            container "https://depot.galaxyproject.org/singularity/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        } else {
//            container "quay.io/biocontainers/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0"
//        }

    input:
    tuple val(filter_name), val(filter_expr)
    tuple val(library), 
        file(pairs_cis_11_lib), file(pairs_cis_22_lib), 
        file(pairs_trans_12_lib), file(pairs_trans_21_lib)
    file(chrom_sizes)

    output:
    tuple val(library), val(filter_name),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis_11.cool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis_22.cool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.trans_12.cool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.trans_21.cool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis.cool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis_trans.cool"),
        emit: cools

    tuple val(library), val(filter_name),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis_11.mcool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis_22.mcool"), 
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.trans_12.mcool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.trans_21.mcool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis.cool"),
        path("${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}.cis_trans.mcool"),
        emit: mcools

    path  "*.version.txt"         , emit: version


    script:
    def software = getSoftwareName(task.process)

    def res_str = params['bin'].resolutions.join(',')
    def res_str_space = params['bin'].resolutions.join(' ')
    // get any additional balancing options, if provided
    def balance_options = params['bin'].get('balance_options','')
    balance_options = ( balance_options ? "--balance-args \"${balance_options}\"": "")
    // balancing flag if it's requested
    def balance_flag = ( params['bin'].get('balance','true').toBoolean() ? "--balance ${balance_options}" : " " )
    def filter_cmd = (filter_expr == '' ? '' : "| pairtools select '${filter_expr}'")

    def cload_cmd = ("cooler cload pairs \
        -c1 2 -p1 3 -c2 4 -p2 5 --assembly ${ASSEMBLY_NAME} \
        ${chrom_sizes}:${MIN_RES}")

    def zoomify_cmd = ("cooler zoomify \
        --nproc ${task.cpus} \
        --resolutions ${res_str} \
        ${balance_flag}")

    def cool_prefix = "${library}.${ASSEMBLY_NAME}.${filter_name}.${MIN_RES}"


    """
    ${params.pairsgz_decompress_cmd} ${pairs_cis_11_lib} ${filter_cmd} \
    | ${cload_cmd} - ${cool_prefix}.cis_11.cool

    ${params.pairsgz_decompress_cmd} ${pairs_cis_22_lib} ${filter_cmd} \
    | ${cload_cmd} - ${cool_prefix}.cis_22.cool

    ${params.pairsgz_decompress_cmd} ${pairs_trans_12_lib} ${filter_cmd} \
    | ${cload_cmd} - ${cool_prefix}.trans_12.cool

    ${params.pairsgz_decompress_cmd} ${pairs_trans_21_lib} ${filter_cmd} \
    | ${cload_cmd} - ${cool_prefix}.trans_21.cool
    

    cooler merge ${cool_prefix}.cis.cool \
        ${cool_prefix}.cis_11.cool \
        ${cool_prefix}.cis_22.cool
        
    cooler merge ${cool_prefix}.cis_trans.cool \
        ${cool_prefix}.cis_11.cool \
        ${cool_prefix}.cis_22.cool \
        ${cool_prefix}.trans_12.cool \
        ${cool_prefix}.trans_21.cool


    ${zoomify_cmd} --out ${cool_prefix}.cis_trans.mcool ${cool_prefix}.cis_trans.cool

    for contact_type in cis_11 cis_22 trans_12 trans_21 cis cis_trans; do
        ${zoomify_cmd} --out ${cool_prefix}.\$contact_type.mcool ${cool_prefix}.\$contact_type.cool
    done
        
    for contact_type in cis_11 cis_22 trans_12 trans_21 cis; do
        for res in ${res_str_space}; do
            python ${baseDir}/bin/h5cp.py \
                ${cool_prefix}.cis_trans.mcool \
                ${cool_prefix}.\$contact_type.mcool \
                /resolution/\$res/bins/weight \
                /resolution/\$res/bins/weight
        done
    done



    cooler --version > ${software}.version.txt
    """
}
