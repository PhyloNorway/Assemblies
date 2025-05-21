#!/usr/bin/env gawk -f

BEGIN {
  # Group definitions
  group_titles["Photosynthesis"] = "Photosynthesis"
  group_titles["ATP Synthesis"] = "ATP Synthesis"
  group_titles["Carbon Fixation"] = "Carbon Fixation"
  group_titles["Electron Transport"] = "Electron Transport"
  group_titles["Gene Expression"] = "Gene Expression"

  group_order[1] = "Photosynthesis"
  group_order[2] = "Electron Transport"
  group_order[3] = "ATP Synthesis"
  group_order[4] = "Carbon Fixation"
  group_order[5] = "Gene Expression"

  complex_group["Photosystem II"] = "Photosynthesis"
  complex_group["Photosystem I"] = "Photosynthesis"
  complex_group["Cytochrome b6/f"] = "Electron Transport"
  complex_group["ATP synthase"] = "ATP Synthesis"
  complex_group["Rubisco"] = "Carbon Fixation"
  complex_group["RNA polymerase"] = "Gene Expression"
  complex_group["Ribosome"] = "Gene Expression"
  complex_group["NADH dehydrogenase"] = "Electron Transport"

  grouped_complex_order["Photosynthesis"][1] = "Photosystem II"
  grouped_complex_order["Photosynthesis"][2] = "Photosystem I"
  grouped_complex_order["Electron Transport"][1] = "Cytochrome b6/f"
  grouped_complex_order["Electron Transport"][2] = "NADH dehydrogenase"
  grouped_complex_order["ATP Synthesis"][1] = "ATP synthase"
  grouped_complex_order["Carbon Fixation"][1] = "Rubisco"
  grouped_complex_order["Gene Expression"][1] = "RNA polymerase"
  grouped_complex_order["Gene Expression"][2] = "Ribosome"

  complexes["Photosystem I"] = "psaA psaB psaC psaI psaJ ycf3 ycf4"
  complexes["Photosystem II"] = "psbA psbB psbC psbD psbE psbF psbH psbN psbZ"
  complexes["Rubisco"] = "rbcL"
  complexes["ATP synthase"] = "atpA atpB atpE atpF atpH atpI"
  complexes["NADH dehydrogenase"] = "ndhA ndhB ndhC ndhD ndhE ndhF ndhG ndhH ndhI ndhJ ndhK"
  complexes["Cytochrome b6/f"] = "petA petB petD petG petN"
  complexes["RNA polymerase"] = "rpoA rpoB rpoC1 rpoC2"
  complexes["Ribosome"] = "rps2 rps3 rps4 rps7 rps8 rps11 rps12 rps14 rps18 rps19 rpl2 rpl14 rpl16 rpl20 rpl23 rrn16S rrn23S rrn4.5S rrn5S"

  complexe_facultatives["Ribosome"] = "rps15 rps16 rpl22 rpl32 rpl33 rpl36"
  complexe_facultatives["Rubisco"] = ""
  complexe_facultatives["Photosystem II"] = "psbI psbJ psbK psbL psbM psbT"
  complexe_facultatives["ATP synthase"] = ""
  complexe_facultatives["NADH dehydrogenase"] = ""
  complexe_facultatives["RNA polymerase"] = "rpoA rpoB rpoC1 rpoC2"
  complexe_facultatives["Cytochrome b6/f"] = "petL"

  split("Ala,Arg,Asn,Asp,Cys,Gln,Glu,Gly,His,Ile,Leu,Lys,fMet,Met,Phe,Pro,Ser,Thr,Trp,Tyr,Val", all_amino_acids, ",")
  for (i in all_amino_acids) {
    aa_set[all_amino_acids[i]] = 1
  }

  region_order_expected[1] = "LSC"
  region_order_expected[2] = "IRB"
  region_order_expected[3] = "SSC"
  region_order_expected[4] = "IRA"

  exit_status = 0

  delete genes
  delete trnas
  delete locus_tags
  delete trna_anticodons_raw

}

/^FT/ {
  if ($0 ~ /^FT {3}[^ ]+/) {
    # Nouveau bloc : on envoie le précédent s'il existe
    if (in_feature) {
      process_feature(feature_text)
    }
    # Démarre un nouveau bloc
    feature_text = substr($0, 6)
    in_feature = 1
  } else if (in_feature) {
    # Ligne de continuation
    feature_text = feature_text "\n" substr($0, 6)
  }
}

# /^FT/ {
#   line = substr($0, 6)
#   if (line ~ /^[^ ]/) {
#     if (in_feature) {
#       process_feature(feature_text)
#     }
#     in_feature = 1
#     feature_text = line "\n"
#   } else if (in_feature) {
#     feature_text = feature_text line "\n"
#   }
#   next
# }

END {
  if (in_feature) {
    process_feature(feature_text)
  }

  print "# Completeness report of chloroplast genome\n"

  print "\n## Chloroplast Genome Structure\n"

    # Taille des régions
    print "| Region | Size | Start postion | End position |"
    print "|--------|------|---------------|--------------|"

  region_order_found_count = 0
  for (i = 1; i <= 4; i++) {
    region = region_order_expected[i]
    if (region in regions) {
      region_order_found[++region_order_found_count] = region

      split(regions[region], coords, ",")
      start = coords[1]
      end = coords[2]
      size = end - start + 1
      region_sizes[region] = size
      print "| " region  " | " size  " bp | " start  " | " end  " |"
    }
  }

  print ""

  if (region_order_found_count < 4) {
    print "- ❌ Incomplete set of LSC/IR/SSC regions"
    exit_status = 1
  } else {
    correct_order = 1
    for (i = 1; i <= 4; i++) {
      if (region_order_found[i] != region_order_expected[i]) {
        correct_order = 0
        break
      }
    }

    if (correct_order) {
      print "- ✅ Regions are in expected order (LSC → IRB → SSC → IRA)"
    } else {
      print "- ❌ Regions are not in expected order"
      printf "  Found order: "
      for (i = 1; i <= 4; i++) {
        printf "%s ", region_order_found[i]
      }
      print ""
      exit_status = 1
    }

    if (region_sizes["IRA"] != region_sizes["IRB"]) {
      print "- ❌ IRA and IRB are not equal in size"
      exit_status = 1
    } else {
      print "- ✅ IRA and IRB have equal size"
    }
  }

  print "\n## Protein complexes\n"

  for (g = 1; g <= length(group_order); g++) {
    group = group_order[g]
    print "\n### " group_titles[group] "\n"
    printf "| Complexe | Found genes | Missing | Compleness | Facultative found | Facultative missing | Locus Tags |\n"
    printf "|----------|---------------|-----------|------------|-----------|------------|------------|\n"

    nc = length(grouped_complex_order[group])
    for (k = 1; k <= nc; k++) {
      complexe = grouped_complex_order[group][k]
      split(complexes[complexe], gene_list, " ")
      total = length(gene_list)
      found = 0
      missing = ""
      tags = ""
      for (i = 1; i <= total; i++) {
        gene = gene_list[i]
        if (gene in genes) {
          found++
          tags = tags genes[gene] " "
        } else {
          missing = missing gene " "
        }
      }
      sub(/[ ]+$/, "", tags)
      sub(/[ ]+$/, "", missing)
      facultatifs = complexe_facultatives[complexe]
      facultatif_found = 0
      facultatif_count = 0
      facultatif_missing = ""
      if (facultatifs != "") {
        split(facultatifs, facultatif_list, " ")
        facultatif_count = length(facultatif_list)
        for (j = 1; j <= facultatif_count; j++) {
          fg = facultatif_list[j]
          if (fg in genes) {
            facultatif_found++
            tags = tags genes[fg] " "
          } else {
            facultatif_missing = facultatif_missing fg " "
          }
        }
      }
      facultatif_status = (facultatif_count > 0) ? sprintf("%d/%d (%.1f%%)", facultatif_found, facultatif_count, (facultatif_found / facultatif_count) * 100) : "–"
      if (facultatif_missing == "") facultatif_missing = "–"
      if (missing == "") {
        missing = "–"
        status = "✅ Complet"
      } else {
        status = "⚠️ Incomplet"
        exit_status = 1
        incomplets[complexe] = missing
      }
      percent = (found / total) * 100
      printf "| %s | %d/%d (%.1f%%) | %s | %s | %s | %s | %s |\n",
             complexe, found, total, percent,
             missing, status,
             facultatif_status, facultatif_missing, tags
    }
  }

  print "\n## tRNA Summary by Amino Acid\n"
  printf "| Amino Acid | Count | Anticodons | Locus Tags |\n"
  printf "|------------|-------|------------|-------------|\n"
  for (aa in trna_count) {
    n = split(trna_anticodons_raw[aa], codons, " ")
    delete seen
    anticodon_list = ""
    for (i = 1; i <= n; i++) {
      if (!(codons[i] in seen)) {
        seen[codons[i]] = 1
        anticodon_list = anticodon_list codons[i] " "
      }
    }
    printf "| %s | %d | %s | %s |\n", aa, trna_count[aa], anticodon_list, trna_locus[aa]
  }

  print ""
  delete missing_aa
  for (aa in aa_set) {
    if (!(aa in trna_count)) {
      print "- ❌ Amino acide " aa " is not represented in tRNA"
      exit_status = 1
      missing_aa[aa]=1
    }
  }

  if (length(missing_aa) == 0) print "- ✅ All amino acids are present"

  print "\n## tRNA-CAU Variants Detected\n"
  cau_types["Met"] = 1
  cau_types["fMet"] = 1
  cau_types["Ile"] = 1
  for (t in cau_types) {
    status = (t in trna_cau_types) ? "✅" : "❌"
    printf "- %s %s (locus: %s)\n", status, t, trna_cau_types[t]
    if (!(t in trna_cau_types)) exit_status = 1
  }

  if (exit_status != 0) {
    print "\n## ❌ Résumé des erreurs\n"

    for (r=1 ; r <=4 ; r++) {
      re = region_order_expected[r]
      if (! re in region_sizes) {
        print "- Not found chloroplast region: " re
      }
    }

    for (c in incomplets) {
      print "- Complexe incomplet: " c " (missing: " incomplets[c] ")"
    }
    for (t in cau_types) {
      if (!(t in trna_cau_types)) {
        print "- Type CAU manquant: " t
      }
    }
    for (aa in aa_set) {
      if (!(aa in trna_count)) {
        print "- Acide aminé non représenté: " aa
      }
    }
    exit exit_status
  }
}

function process_feature(text,   lines, i, gene, locus_tag, anticodon, match_arr, aa, note) {
  split(text, lines, "\n")
  gene = ""
  locus_tag = ""
  aa = ""
  anticodon = ""
  for (i in lines) {
    line = lines[i]
    if (match(line, /\/gene="([^"]+)"/, match_arr)) {
      gene = match_arr[1]
      gene = gensub(/_[0-9]+$/, "", "g", gene)
    }
    if (match(line, /\/locus_tag="([^"]+)"/, match_arr)) {
      locus_tag = match_arr[1]
    }
    if (match(line, /\/note="([^"]+)"/, match_arr)) {
      note = match_arr[1]
    }
  }
  if (gene ~ /^tRNA/) {
    if (match(gene, /tRNA-(f?[A-Z][a-z]{2})\(([A-Z]{3})\)/, match_arr)) {
      aa = match_arr[1]
      anticodon = tolower(match_arr[2])
    }

    if (aa != "") {
      trna_count[aa]++
      locus_tag = (locus_tag != "") ? locus_tag : gene
      trna_locus[aa] = trna_locus[aa] locus_tag " "
      if (anticodon != "") {
        trna_anticodons[aa][anticodon] = 1
        trna_anticodons_raw[aa] = trna_anticodons_raw[aa] anticodon " "
      }
      if (anticodon == "cau") {
        if (aa == "Ile") {
          trna_cau_types["Ile"] = locus_tag
        } else if (aa == "fMet") {
          trna_cau_types["fMet"] = locus_tag
        } else if (aa == "Met") {
          trna_cau_types["Met"] = locus_tag
        }
      }
    }
  }

  if (gene != "") {
    genes[gene] = locus_tag
    if (locus_tag == "") {
      genes[gene] = gene
    }
  }

  if (match(text, /\/note="([^"]+)"/, match_arr)) {
    note = match_arr[1]
    if (match(note, /large single copy region \(LSC\)/)) {
      regions["LSC"] = get_coords(text)
    } else if (match(note, /small single copy region \(SSC\)/)) {
      regions["SSC"] = get_coords(text)
    } else if (match(note, /left inverted repeat A; IRA/)) {
      regions["IRA"] = get_coords(text)
    } else if (match(note, /left inverted repeat B; IRB/)) {
      regions["IRB"] = get_coords(text)
    }
  }

}

function get_coords(feature_text) {
  # Prendre la première ligne du bloc
  split(feature_text, lines, "\n")
  line = lines[1]

  # Extraire la portion contenant les coordonnées (format standard EMBL : cols 6-21)
  split(line, fields)
  loc = fields[2]
  gsub(/[ \t]/, "", loc)

  # Extraire les deux bornes numériques
  if (match(loc, /^([0-9]+)\.\.([0-9]+)$/, coords)) {
    return coords[1] "," coords[2]
  }

  return "0,0"
}
