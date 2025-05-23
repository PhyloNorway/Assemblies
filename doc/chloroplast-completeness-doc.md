# 🌿 `chloroplast-completeness.awk`

AWK script for analyzing the **completeness of chloroplast protein complexes** from EMBL annotation files. It generates a **Markdown report** and an **interactive D3.js visualization**.

---

## ✨ Purpose

This script evaluates the completeness of **manually defined chloroplast protein complexes** by parsing gene annotations from EMBL flat files.

It allows you to:
- Detect annotated genes from the EMBL `FT` (Feature Table) section,
- Verify the presence/absence of complexes such as ATP synthase, photosystems, NDH, etc.,
- Generate an interactive graph (D3.js) showing complex topology with gene presence/absence,
- Identify the location of detected genes within LSC, SSC, or IR regions.

---

## 🧾 Input

- **A valid EMBL file** (`.embl` or `.txt`), structured with a `FT` section that includes annotations such as:
  - `gene`, `CDS`, or `tRNA` keys,
  - `/gene="..."` qualifiers.

The file **should include annotations for LSC, SSC, IRa, IRb regions** to enable region detection.

---

## 📤 Output

1. **Markdown table** listing:
   - Each complex,
   - Genes present,
   - Genes missing,
   - Overall completeness percentage.

2. **D3.js interactive graph** exported as a standalone HTML file.

---

## 🧬 Annotation Features Parsed

The script processes the `FT` (Feature Table) lines in EMBL format.

### Gene detection

Genes are extracted from entries like:
```txt
FT   gene            123..456
FT                   /gene="atpA"
```

The parser:
- Supports multi-line `FT` entries,
- Extracts `/gene="..."` values (case-insensitive),
- Ignores pseudogenes or malformed entries.

### Region detection: LSC / SSC / IR

If the following region annotations are present, they are parsed:
```txt
FT   misc_feature    complement(123..456)
FT                   /note="IRa"
```

Accepted labels:
- `LSC`, `SSC`, `IRA`, `IRB` (case-insensitive)

The script maps each gene to its corresponding region, if coordinates match.

---

## 📊 Visualization

The output includes a D3.js graph where:
- Nodes represent genes,
- Node colors indicate presence (green) or absence (gray),
- Edges represent protein complex groupings.

Interactive features:
- Hover tooltips with gene and region,
- Clickable highlighting of complex paths.

---

## 🧠 Notes

- The script is written in `gawk` and should be POSIX-compliant.
- Ideal for comparative genomics, genome QC, or plastome structure studies.
- Custom complexes can be defined in the script header or external config file.

