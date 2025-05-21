#!/bin/bash
#
# Downloads metadata for a given ENA project ID from the EBI FTP server and
# saves it to TSV files in the current directory. The script then processes
# these files to download the corresponding XML files.
#
# Usage: ./Download.sh <PROJECT_ID> 
# Example: ./Download.sh PRJEB47813
#
# Dependencies: curl, bash, tail, and a Unix-like environment.
#
# The script create in the current directory:
# - A 'xml_runs' folder containing the XML files for each run of the project
# - A 'xml_samples' folder containing the XML files for each sample of the
#   project
# - A 'xml_experiments' folder containing the XML files for each experiment of
#   the project
#
# Author: Eric Coissac <eric.coissac@metabarcoding.org> Version: 1.0 Date:
# 2025-05-18
#
set -euxo pipefail
PROJECT_ID=$1
mkdir -p xml_runs xml_samples xml_experiments


# 1. Récupérer la liste des runs avec les accessions d'expériences et de samples
echo "🔍 Fetching run metadata..."
curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${PROJECT_ID}&result=read_run&fields=run_accession,experiment_accession,sample_accession&format=tsv" -o runs.tsv

tail -n +2 runs.tsv | while IFS=$'\t' read -r run_acc exp_acc sample_acc; do
  # 2. Télécharger le fichier XML du RUN
  if [[ ! -f "xml_runs/${run_acc}.xml" ]]; then
    echo "⬇️ Downloading RUN ${run_acc}"
    curl -s "https://www.ebi.ac.uk/ena/browser/api/xml/${run_acc}" -o "xml_runs/${run_acc}.xml"
  fi

  # 3. Télécharger le fichier XML de l’EXPERIMENT
  if [[ ! -f "xml_experiments/${exp_acc}.xml" ]]; then
    echo "⬇️ Downloading EXPERIMENT ${exp_acc}"
    curl -s "https://www.ebi.ac.uk/ena/browser/api/xml/${exp_acc}" -o "xml_experiments/${exp_acc}.xml"
  fi

  # 4. Télécharger le fichier XML du SAMPLE
  if [[ ! -f "xml_samples/${sample_acc}.xml" ]]; then
    echo "⬇️ Downloading SAMPLE ${sample_acc}"
    curl -s "https://www.ebi.ac.uk/ena/browser/api/xml/${sample_acc}" -o "xml_samples/${sample_acc}.xml"
  fi
done

echo "✅ All XML files downloaded."