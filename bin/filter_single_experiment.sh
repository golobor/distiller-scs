SAMPLE=$1
OUTPUT_FOLDER=$2
INPUT_S4T_PAIRS=$3

MIN_MAPQ=$4
MIN_RIGHT_MUTS=$5
MAX_WRONG_MUTS=$6

#FILTER_SUMMARY="mapq_${MIN_MAPQ}.phred_30.right_muts_${MIN_RIGHT_MUTS}.wrong_muts_${MAX_WRONG_MUTS}"

MAPQ_FILTER="((mapq1 >= ${MIN_MAPQ}) and (mapq2 >= ${MIN_MAPQ}))"

SIDE1_HAS_AG="(int(n_AG_muts_phred30_1) >= ${MIN_RIGHT_MUTS})" 
SIDE1_HAS_TC="(int(n_TC_muts_phred30_1) >= ${MIN_RIGHT_MUTS})" 
SIDE2_HAS_AG="(int(n_AG_muts_phred30_2) >= ${MIN_RIGHT_MUTS})" 
SIDE2_HAS_TC="(int(n_TC_muts_phred30_2) >= ${MIN_RIGHT_MUTS})" 
SIDE1_NO_AG="(int(n_AG_muts_phred30_1) <= ${MAX_WRONG_MUTS})" 
SIDE1_NO_TC="(int(n_TC_muts_phred30_1) <= ${MAX_WRONG_MUTS})" 
SIDE2_NO_AG="(int(n_AG_muts_phred30_2) <= ${MAX_WRONG_MUTS})" 
SIDE2_NO_TC="(int(n_TC_muts_phred30_2) <= ${MAX_WRONG_MUTS})" 

SIDE1_IS_1="(${SIDE1_HAS_AG} and ${SIDE1_NO_TC})"
SIDE2_IS_1="(${SIDE2_HAS_AG} and ${SIDE2_NO_TC})"
SIDE1_IS_2="(${SIDE1_HAS_TC} and ${SIDE1_NO_AG})"
SIDE2_IS_2="(${SIDE2_HAS_TC} and ${SIDE2_NO_AG})"

IS_CIS_11="(${SIDE1_IS_1} and ${SIDE2_IS_1})"
IS_CIS_22="(${SIDE1_IS_2} and ${SIDE2_IS_2})"
IS_TRANS_12="(${SIDE1_IS_1} and ${SIDE2_IS_2})"
IS_TRANS_21="(${SIDE1_IS_2} and ${SIDE2_IS_1})"
        
IS_CIS="(${IS_CIS_1} or ${IS_CIS_2})"
IS_TRANS="(${IS_TRANS_12} or ${IS_TRANS_21})"

echo "filtering..."

pairtools select "(${MAPQ_FILTER} and ${IS_CIS_11})" ${INPUT_S4T_PAIRS} \
    -o ${OUTPUT_FOLDER}/${SAMPLE}.cis_11.pairs.gz

pairtools select "(${MAPQ_FILTER} and ${IS_CIS_22})" ${INPUT_S4T_PAIRS} \
    -o ${OUTPUT_FOLDER}/${SAMPLE}.cis_22.pairs.gz
    
pairtools select "(${MAPQ_FILTER} and ${IS_TRANS_12})" ${INPUT_S4T_PAIRS} \
    -o ${OUTPUT_FOLDER}/${SAMPLE}.trans_12.pairs.gz
    
pairtools select "(${MAPQ_FILTER} and ${IS_TRANS_21})" ${INPUT_S4T_PAIRS} \
    -o ${OUTPUT_FOLDER}/${SAMPLE}.trans_21.pairs.gz
