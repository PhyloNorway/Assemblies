# Assemblies
Distribution of the PhyloNorway Chloroplast genomes and nuclear rDNA cluster assemblies


## Scripts

All the scripts are stored in the `scripts` directory.

### Config files

You must have in your home directory a `.ENA_passwd` file containing one line per submitter.

```
porject_name:ena_login:ena_password
```

example : 

```
PhyloNorway:Webin-00000:xxyyyzzz
```

### Dependencies

- `curl`
- `xmlstarlet`
- `gawk`
- `bash`
- 

### Annotation script

### Annotation checking scripts

## Data

The data are stored in the `data` directory.

### Assembly files

They are stored in the `sequences` directory in tow sub directories

- raw : contains raw sequences (fasta format)
- annotated: contains EMBL formatted annotation of the genomes 

The names of the files follow this pattern : 

`species_name.herbarium_code.library.(chloro|rdnanuc).(raw.fasta|.fasta|.embl).gz`

- Species name came from NCBI scientific names corresponding to the taxid
  - Remove from the names:
    - dots
    - single quotes
    - parentheses
    - square brackets 
  - spaces are replaced by underscores 
- Herbarium code is the herbarium number where the specimen was taken
  - It follows the format: 
    - `TROM_V_####` for Tromsoe herbarium
    - `SB###` for Oslo herbarium ???
- Library is the name of the sequencing library used to generate the sequence 
  - It's a two parts name separated by an underscore, each part is composed of two
    three capital letters.
- Sequence types:
  - `chloro`: for the chloroplast genomes
  - `rdnanuc`: for the nuclear rDNA cluster
- Suffixes:
  - `.raw.fasta.gz` for raw sequences as produced by the assembler
  - `.fasta.gz` for sequences that have converted to fasta format from EMBL file
  - `.embl.gz` for EMBL format file
