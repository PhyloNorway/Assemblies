# Creating and submitting an ENA study/project for each family

Retrieve all LOCUS_TAG_PREFIX names from a family and format them for XML file

`grep "Asteraceae" ../ena_metadata.csv | cut -f 7,11 -d, | sort | cut -f 2 -d, | sed 's/^/            <LOCUS_TAG_PREFIX>/' | sed 's/$/<\/LOCUS_TAG_PREFIX>/'`

Maximum number of LOCUS_TAG_PREFIXes that can be uploaded to a single project is 100-120, so larger families will be divided into multiple files.

`grep "Asteraceae" ena_metadata.csv | cut -f 7 -d, | sort | cut -f 1 -d_ | head -93 | uniq -c | awk '{printf "| %s | %s |\n", $2, $1}' | sed 's/$/ Asteraceae_1/' `

| Genus         | Number of specimens | Project_file |
|---------------|---------------------|--------------|
| Achillea | 3 | Asteraceae_1
| Ambrosia | 1 | Asteraceae_1
| Antennaria | 13 | Asteraceae_1
| Anthemis | 2 | Asteraceae_1
| Arctanthemum | 1 | Asteraceae_1
| Arctium | 3 | Asteraceae_1
| Arnica | 5 | Asteraceae_1
| Artemisia | 11 | Asteraceae_1
| Bellis | 1 | Asteraceae_1
| Bidens | 2 | Asteraceae_1
| Calendula | 1 | Asteraceae_1
| Carduus | 1 | Asteraceae_1
| Carlina | 1 | Asteraceae_1
| Centaurea | 6 | Asteraceae_1
| Cicerbita | 3 | Asteraceae_1
| Cichorium | 1 | Asteraceae_1
| Cirsium | 6 | Asteraceae_1
| Cota | 3 | Asteraceae_1
| Crepis | 5 | Asteraceae_1
| Doronicum | 4 | Asteraceae_1
| Echinops | 2 | Asteraceae_1
| Erigeron | 18 | Asteraceae_1
| Eupatorium | 1 | Asteraceae_2
| Eurybia | 1 | Asteraceae_2
| Filago | 1 | Asteraceae_2
| Galinsoga | 2 | Asteraceae_2
| Glebionis | 2 | Asteraceae_2
| Gnaphalium | 1 | Asteraceae_2
| Helianthus | 1 | Asteraceae_2
| Helichrysum | 1 | Asteraceae_2
| Hieracium | 30 | Asteraceae_2
| Hulteniella | 1 | Asteraceae_2
| Hypochaeris | 2 | Asteraceae_2
| Inula | 4 | Asteraceae_2
| Jacobaea | 1 | Asteraceae_2
| Lactuca | 1 | Asteraceae_2
| Lapsana | 1 | Asteraceae_2
| Leontodon | 1 | Asteraceae_2
| Leucanthemum | 2 | Asteraceae_2
| Ligularia | 3 | Asteraceae_2
| Matricaria | 3 | Asteraceae_2
| Nabalus | 1 | Asteraceae_2
| Omalotheca | 4 | Asteraceae_2
| Packera | 1 | Asteraceae_2
| Pentanema | 1 | Asteraceae_2
| Petasites | 3 | Asteraceae_2
| Pilosella | 8 | Asteraceae_2
| Rudbeckia | 1 | Asteraceae_2
| Saussurea | 1 | Asteraceae_2
| Scorzoneroides | 3 | Asteraceae_3
| Senecio | 10 | Asteraceae_3
| Serratula | 1 | Asteraceae_3
| Silybum | 1 | Asteraceae_3
| Sinacalia | 1 | Asteraceae_3
| Solidago | 4 | Asteraceae_3
| Sonchus | 4 | Asteraceae_3
| Symphyotrichum | 3 | Asteraceae_3
| Tanacetum | 3 | Asteraceae_3
| Taraxacum | 30 | Asteraceae_3
| Telekia | 1 | Asteraceae_3
| Tephroseris | 5 | Asteraceae_3
| Tragopogon | 1 | Asteraceae_3
| Tripleurospermum | 4 | Asteraceae_3
| Tripolium | 1 | Asteraceae_3
| Tussilago | 1 | Asteraceae_3
| Xanthium | 1 | Asteraceae_3



TEST_SERVER="https://wwwdev.ebi.ac.uk/ena/submit/drop-box"
PROD_SERVER="https://www.ebi.ac.uk/ena/submit/drop-box"

`curl -u $LOGIN:$PASSWD -F "SUBMISSION=@submission.xml" -F "PROJECT=@Asteraceae_proj_1.xml" "https://wwwdev.ebi.ac.uk/ena/submit/drop-box/submit"`