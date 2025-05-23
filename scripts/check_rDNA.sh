#!/usr/bin/env bash
#
# This script checks an EMBL file describing a nuclear rDNA gene cluster as
# annotated by organnote (http://metabarcoding.org/annot). It checks for the
# presence, the completeness and the relative locations of expected rRNA genes: 
# - 18S, 
# - ITS1, 
# - 5.8s, 
# - ITS2, 
# - rrn28S
#
# Usage: check_rDNA.sh <EMBL file>
#
# The script outputs a list of genes that are missing, incomplete or located in the wrong place.
# It also prints out the line numbers where these occur.
#

# Author: Eric Coissac (eric.coissac@metabarcoding.org)
# Date: 2025/05/18
# Version: 1.0
#

file="$1"

# ordre attendu
expected=( "18S rRNA" "ITS1" "5.8S rRNA" "ITS2" "28S rRNA" )

declare -A ln pos partial

lineno=0
while IFS= read -r line || [[ -n $line ]]; do
  ((lineno++))
  gene=""
  location=""

  # rRNA (18S, 5.8S, 28S)
  if [[ $line =~ ^FT[[:space:]]+rRNA[[:space:]]+([<>]?[0-9]+\.\.[<>]?[0-9]+) ]]; then
    location="${BASH_REMATCH[1]}"
    # qualifier 1
    IFS= read -r qual1 || break; ((lineno++))
    if [[ $qual1 =~ /gene=\"([^\"]+)\" ]]; then
      gene="${BASH_REMATCH[1]}"
    else
      # qualifier 2 (pour 5.8S via product)
      IFS= read -r qual2 || break; ((lineno++))
      if [[ $qual2 =~ /product=\".*5\.8S ]]; then
        gene="5.8S rRNA"
      fi
    fi

  # misc_RNA (ITS1, ITS2)
  elif [[ $line =~ ^FT[[:space:]]+misc_RNA[[:space:]]+([<>]?[0-9]+\.\.[<>]?[0-9]+) ]]; then
    location="${BASH_REMATCH[1]}"
    # qualifier 1 : gene
    IFS= read -r qual1 || break; ((lineno++))
    if [[ $qual1 =~ /gene=\"ITS1\" ]]; then
      gene="ITS1"
    elif [[ $qual1 =~ /gene=\"ITS2\" ]]; then
      gene="ITS2"
    else
      # qualifier 2 : note
      IFS= read -r qual2 || break; ((lineno++))
      if [[ $qual2 =~ ITS1 ]]; then
        gene="ITS1"
      elif [[ $qual2 =~ ITS2 ]]; then
        gene="ITS2"
      fi
    fi
  fi

  if [[ -n $gene ]]; then
    ln["$gene"]=$lineno
    pos["$gene"]=$location
    [[ $location =~ [\<\>] ]] && partial["$gene"]=1 || partial["$gene"]=0
  fi
done < "$file"

# validation
ok=1
prev=0
for feat in "${expected[@]}"; do
  if [[ -z "${ln[$feat]:-}" ]]; then
    echo "❌ Missing feature: $feat"
    ok=0
    continue
  fi
  if (( partial[$feat] )); then
    echo "❌ Partial location for $feat: ${pos[$feat]}"
    ok=0
  fi
  if (( ln[$feat] < prev )); then
    echo "❌ Out of order: $feat at line ${ln[$feat]} after previous at $prev"
    ok=0
  fi
  prev=${ln[$feat]}
done

if (( ok )); then
  echo "✅ All features complete and in correct order"
  exit 0
else
  exit 1
fi
