#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METADATA="$SCRIPT_DIR/../data/ena_metadata.csv"
DORGANNOT=dorgannot
CHECK="${SCRIPT_DIR}/check_Chloro.gawk"


fasta_file=$1
markdown_file=${fasta_file/.raw.fasta/.md}
embl_file=${fasta_file/.raw.fasta/.embl}
invalid_file=${fasta_file/.raw.fasta/.invalid}

simpler=${fasta_file/.chloro.raw.fasta/}
library=${simpler##*.}



eval $(csvsql --table data \
            --query "select * from data where library='${library}'" \
            $METADATA \
            | awk -F',' '
                (NR==1) {split($0,h);next}
                        {n=split($0,d)}
                END {for(i=1;i<=n;i++) {print "export "h[i] "=" d[i]}}
            ')

if [[ -z $specimen ]]; then
    library=${library/:/_}
    output_dir="$SCRIPT_DIR/../data/sequences/raw/${family_name}"
    mkdir -p "$output_dir"

    echo -e "\n\n\n========================================================\n" 1>&2
    echo "Start to check: ${scientific_name} specimen: ${specimen_id}" 1>&2
    echo "Library: [${library}]" 1>&2
    echo "Family name: [${family_name}]" 1>&2

    output_dir="$(cd $output_dir && pwd)"
    output_file="$output_dir/${scientific_name}.${specimen_id}.${library}.chloro.raw.fasta.gz"

    if [[ -e $output_file && ! -e $invalid_file ]]; then
        echo "File already processed: $output_file" 1>&2
        exit 1
    fi
    echo -e "\n========================================================\n\n\n" 1>&2

    TMPDIR=$(mktemp -d "./tmpdir.XXXXXX") \
    && cp "$fasta_file" "$TMPDIR/genome.fasta" \
    && pushd "$TMPDIR" \
    && ${DORGANNOT} -c "genome.fasta" > "../$embl_file" \
    && popd  \
    && rm -rf "$TMPDIR" 

    if  ${CHECK} "${embl_file}" > "$markdown_file" ; then
        obiconvert -Z "$fasta_file" > "$output_file" \
        || { rm -f "$output_file"; echo "Failed to convert $embl_file to fasta format."; exit 1;} \
    else
        echo "Invalid Chloroplast" 1>&2
        touch "${invalid_file}"
        exit 1
    fi
fi
