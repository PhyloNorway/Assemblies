#!/bin/bash
#set -euo pipefail

# Function to retrieve the family taxid and name from a given species taxid
function family() {
    local taxid=$1
    efetch -db taxonomy -id "$taxid" -format xml \
    | xmlstarlet sel -t -m "//LineageEx/Taxon[Rank='family']" \
                     -v "TaxId" -o "," -v "ScientificName" -n
}

# CSV header
echo "library,specimen_id,sample_accession,experiment_accession,run_accession,ncbi_taxid,scientific_name,family_taxid,family_name,country,prefix"

runfilescount=0
# Main loop over run XML files
for run_file in xml_runs/*.xml ; do
    ((runfilescount++))
    run_accession=$(xmlstarlet sel -t -v "//RUN/@accession" "$run_file")
    exp_accession=$(xmlstarlet sel -t -v "//RUN/EXPERIMENT_REF/@accession" "$run_file")

    exp_file="xml_experiments/${exp_accession}.xml"
    if [[ ! -f "$exp_file" ]]; then
        echo "⚠️  Cannot locate experiment file $exp_file — skipping" 1>&2
        continue
    fi

    sample_accession=$(xmlstarlet sel -t -v "//SAMPLE_DESCRIPTOR/IDENTIFIERS/EXTERNAL_ID[./@namespace='BioSample']" "$exp_file")
    
    if [[ -z "$sample_accession" ]]; then
        echo "⚠️  No sample accession found in $run_file — skipping" 1>&2
        continue
    fi

    sample_file="xml_samples/${sample_accession}.xml"

    # echo "Processing $run_accession (exp: $exp_accession, sample: $sample_accession)" 1>&2

    if [[ ! -f "$exp_file" || ! -f "$sample_file" ]]; then
        echo "⚠️  Missing $exp_file or sample file for $run_accession (sample $sample_accession) — skipping" 1>&2
        continue
    fi

    
    library=$(xmlstarlet sel -t -v "//IDENTIFIERS/SUBMITTER_ID[./@namespace='Genoscope']" "$run_file" \
              | sed -E 's/run_(.+)_(.+)OS..?_.*/\1:\2/')

    if [[ -z "$library" ]] ; then
        library=$(xmlstarlet sel -t -v "//DATA_BLOCK/FILES/FILE[./READ_LABEL='F1']/@filename" "$run_file" \
        | cut -d/ -f 4 \
        | sed -E 's/(.+)_(.+)OS..?_.*/\1:\2/')
    fi

    sample_accession=$(xmlstarlet sel -t -v "//SAMPLE/@accession" "$sample_file")
    specimen_id=$(xmlstarlet sel  -t -v "//SAMPLE/@alias" "$sample_file")
    prefix="${specimen_id/TROM_V_/TV}"
    scientific_name=$(xmlstarlet sel -t -v "//SAMPLE_NAME/SCIENTIFIC_NAME" "$sample_file" \
                        | tr ' ' '_'\
                        | tr -d "[]().'")
    ncbi_taxid=$(xmlstarlet sel -t -v "//SAMPLE_NAME/TAXON_ID" "$sample_file")
    country=$(xmlstarlet sel -t -v "//SAMPLE/SAMPLE_ATTRIBUTES/SAMPLE_ATTRIBUTE[./TAG='geographic location (country and/or sea)']/VALUE" "$sample_file")

    IFS=',' read -r family_taxid family_name <<< "$(family "$ncbi_taxid")"
    # family_taxid=xxx
    # family_name=xxx
    echo "${library},${specimen_id},${sample_accession},${exp_accession},${run_accession},${ncbi_taxid},${scientific_name},${family_taxid},${family_name},${country},${prefix}"
done

echo "📚 $runfilescount processed." 1>&2
