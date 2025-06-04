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

draw_svg() {
  local genome_length=$1
  local svg_width=800
  local bar_height=20
  local margin=50
  local scale
  scale=$(gawk -v len="$genome_length" -v width="$svg_width" 'BEGIN{print width / len}')

  echo "<svg xmlns='http://www.w3.org/2000/svg' width=\"$((svg_width + 40))\" height=\"200\">"
  
  echo "<rect x=\"20\" y=\"100\" width=\"$svg_width\" height=\"10\" fill=\"black\" />"

  for gene in "${expected[@]}"; do
    s=${gene_start[$gene]}
    e=${gene_end[$gene]}
    height=16

    s_px=$(gawk -v s="$s" -v scale="$scale" -v m="$margin" 'BEGIN{printf "%.1f", s * scale + m}')
    e_px=$(gawk -v e="$e" -v scale="$scale" -v m="$margin" 'BEGIN{printf "%.1f", e * scale + m}')
    width_px=$(gawk -v s="$s_px" -v e="$e_px" 'BEGIN{printf "%.1f", e - s}')

    if [[ "$gene" == ITS* ]]; then
      # ITS: bar above
      echo "<rect x=\"$s_px\" y=\"60\" width=\"$width_px\" height=\"$height\" fill=\"orange\" stroke=\"black\" />"
      echo "<text x=\"$s_px\" y=\"55\">$gene</text>"
    else
      # rRNA: box with arrow below
      arrow_body_w=$(gawk -v w="$width_px" 'BEGIN{printf "%.1f", w - 5}')
      arrow_x1="$s_px"
      arrow_x2=$(gawk -v x="$s_px" -v w="$arrow_body_w" 'BEGIN{printf "%.1f", x + w}')
      arrow_tip="$e_px"

      # Ajuste la hauteur de position pour 5.8S
      if [[ "$gene" == "5.8S rRNA" ]]; then
        y_base=145
        text_y=175
      else
        y_base=120
        text_y=150
      fi

      path="M $arrow_x1 $y_base L $arrow_x2 $y_base L $arrow_x2 $y_base L $arrow_tip $((y_base + 8)) L $arrow_x2 $((y_base + 16)) L $arrow_x2 $((y_base + 16)) L $arrow_x1 $((y_base + 16)) Z"
      echo "<path d=\"$path\" fill=\"#4da6ff\" stroke=\"black\" />"
      echo "<text x=\"$s_px\" y=\"$text_y\">$gene</text>"
    fi
  done

  echo "</svg>"
}

file="$1"

# ordre attendu
expected=( "18S rRNA" "ITS1" "5.8S rRNA" "ITS2" "28S rRNA" )

declare -A ln pos partial gene_start gene_end

lineno=0
while IFS= read -r line || [[ -n $line ]]; do
  ((lineno++))
  gene=""
  location=""

  # rRNA (18S, 5.8S, 28S)
  if [[ $line =~ ^ID[[:space:]][[:space:]][[:space:]].+\;[[:space:]]([0-9]+)[[:space:]]BP\.$ ]]; then
    seq_length="${BASH_REMATCH[1]}"
  fi
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
    if [[ $location =~ ([<>]?)([0-9]+)\.\.([0-9]+)([<>]?) ]]; then
      start="${BASH_REMATCH[2]}"
      end="${BASH_REMATCH[3]}"
      gene_start["$gene"]=$start
      gene_end["$gene"]=$end
    else
      echo "⚠️ Cannot parse coordinates for $gene at line $lineno: $location" >&2
    fi
  fi

done < "$file"

# validation
ok=1
prev=0
rank=0

echo -e "\n## Feature detection \n"

for feat in "${expected[@]}"; do
  featok=1
  if [[ -z "${ln[$feat]:-}" ]]; then
    echo "- ❌ Missing feature: $feat"
    ok=0
    featok=0
    continue
  fi
  if (( partial[$feat] )); then
    echo "- ❌ Partial location for $feat: ${pos[$feat]}"
    ok=0
    featok=0
  fi
  if (( ln[$feat] < prev )); then
    echo "- ❌ Out of order: $feat at line ${ln[$feat]} after previous at $prev"
    ok=0
    featok=0
  fi
  prev=${ln[$feat]}
  if (( featok )); then
    rank=$(( rank + 1 ))
    echo "- ✅ Feature: $feat detected at rank $rank"
  fi
done

echo -e "\n## Summary status \n"


if (( ok )); then
  echo "✅ All features complete and in correct order"

  echo -e "\n## Feature map\n"
 
  draw_svg $seq_length

  exit 0
else
  echo "❌ Nuclear rDNA cluster sequence validation failed."
  exit 1
fi
