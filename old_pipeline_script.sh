#!/bin/bash

# Authors: Sander Wuyts (main), Stijn Wittouck (very small contributions), Wannes Van Beeck (very small adjustments)
# Last adapted: 20210326

# parameters
THREADS=16
INPUT_FILE=/media/hdd/seqdata_wgs/src/input_files/20220221_INPUTFILE.tsv

# shovill dependencies
export PATH=$PATH:/media/harddrive/tools/shovill/bin
export PATH=$PATH:/media/harddrive/tools/FLASH-1.2.11
export PATH=$PATH:/media/harddrive/tools/Lighter
export PATH=$PATH:/media/harddrive/tools/mash-Linux64-v2.1
export PATH=$PATH:/media/harddrive/tools/megahit_v1.1.4_LINUX_CPUONLY_x86_64-bin
export PATH=$PATH:/media/harddrive/tools/pilon_1.22
export PATH=$PATH:/media/harddrive/tools/samclip
export PATH=$PATH:/media/harddrive/tools/SKESA
export PATH=$PATH:/media/harddrive/tools/spades/SPAdes-3.12.0-Linux/bin
export PATH=$PATH:/media/harddrive/tools/velvet
export PATH=$PATH:/media/harddrive/tools/any2fasta

# prokka dependencies
export PATH=$PATH:/media/harddrive/tools/prokka/bin
export PATH=$PATH:/media/harddrive/tools/barrnap/bin

# abricate dependencies
export PATH=$PATH:/media/harddrive/tools/abricate/bin

# antismash dependencies
export PATH=$PATH:/media/harddrive/tools/antismash

# Shovill dependency check
echo "CHECKING SHOVILL DEPENDENCIES"
shovill --check >  dependency_check.out 2>&1
cat dependency_check.out | grep -q 'please install it' && \
  echo "failed: check dependency_check.out" && exit 1

## If shovill throws error regarding pilon installation please follow
## instructions in
## /media/harddrive/tools/pilon_1.22/make_pilon_available_in_path.README
## Use the same commands to install trimmomatic

rm dependency_check.out

# Start analysis
echo
echo STARTING ANALYSIS
mkdir -p ../results/genomes
cd ../results/genomes

# Loop over lines of input file with genomes
while IFS="	" read -r f1 f2 f3 f4 f5 f6 f7
do

	# Create output folder
	mkdir -p $f1
	cd $f1

	# STEP 01: Assemble genome

	echo
	echo 'RUNNING ASSEMBLY ON' $f1

	shovill \
	  --R1 /media/harddrive/seqdata_wgs/data/seqdata/$f2/$f3 \
		--R2 /media/harddrive/seqdata_wgs/data/seqdata/$f2/$f4 \
		--outdir 01_assembly \
		--cpus $THREADS \
		--tmpdir ./tmp_shovill \
		--ram 12 > shovill.out

	rm shovill.out

	# STEP 02: CheckM quality check

	echo
  echo 'PERFORMING QC CHECK ON' $f1

  mkdir -p 02_QC
	cd 02_QC

	mkdir -p in
	cp ../01_assembly/contigs.fa in/$f1.fna

	python2.7 /usr/local/bin/checkm lineage_wf -t 16 in/ out/ --reduced_tree
	python2.7 /usr/local/bin/checkm qa \
			out/lineage.ms \
			out/ \
			-t $THREADS \
			-o 2 \
			--tab_table \
			-f results.tsv
	rm -r in/

	# Check if completeness is sufficient

	COMPLETENESS=$(tail -n1 results.tsv | cut -f 6) # Extract completeness

	if (( $(echo "$COMPLETENESS < 94" | bc -l) )); then
		echo "Completeness lower than 94"
		echo "Stopping analysis for" $f1

		cd ../

    # Print metadata file
 		echo -e "$f1\t$f5\t$f6\t$f7" > ${f1}_metadata.tsv

		# Create Genome Report
		Rscript /media/harddrive/seqdata_wgs/src/launch_rmarkdown_script.R $(pwd)

		# Continue with next entry
		cd ../
		continue
	fi

	mv out/* .
	rm -r out

	cd ../

	# STEP 03: Annotation

  echo
  echo 'PERFORMING ANNOTATION ON' $f1	

	prokka 01_assembly/contigs.fa \
	  --outdir 03_annotation \
		--prefix $f1 \
		--locustag $f1 \
		--compliant \
		--cpus $THREADS \
		--quiet \
		> prokka.out

	gzip 03_annotation/$f1.*

  # STEP 04: 16S identification

  echo
  echo 'PERFORMING IDENTIFICATION ON 16S GENE(S)' $f1

	mkdir -p 04_ID

	cd 04_ID/

	## Predict rRNA gene(s)
	cp ../03_annotation/$f1.fna.gz .
	gunzip $f1.fna.gz
	barrnap $f1.fna --outseq rRNA.fasta # Predict 16S rRNA gene(s)

	## Extract 16S rRNA gene(s)
	grep -A1 "16S" rRNA.fasta > 16S_rRNA.fasta
	## Rename fasta header or else BLCA won't work
	awk '/^>/{print ">" ++i; next}{print}' < 16S_rRNA.fasta > out.fasta
	mv out.fasta 16S_rRNA.fasta

	## Perform classification with BLCA
	python /media/harddrive/tools/BLCA/2.blca_main.py -i 16S_rRNA.fasta \
	  -q /media/harddrive/tools/BLCA/db/16SMicrobial \
		-r /media/harddrive/tools/BLCA/db/16SMicrobial.ACC.taxonomy
	cut -f2 16S_rRNA.fasta.blca.out > 16S_rRNA_blca_classification.out

	## Cleanup
	rm rRNA.fasta ${f1}.fna ${f1}.fna.fai 16S_rRNA.fasta.blastn \
	  16S_rRNA.fasta.blca.out

	cd ../

	# STEP 05: Resistome

	echo
	echo 'FINDING ANTIBIOTIC GENES IN' $f1

	mkdir -p 05_resistome
	cd 05_resistome

	abricate -db resfinder --quiet ../03_annotation/$f1.gbk.gz > resistome_out.tsv

	cd ../

  # STEP 06: Virulence

  echo
  echo 'FINDING VIRULENCE GENES IN' $f1

  mkdir -p 06_virulence
  cd 06_virulence

	abricate -db vfdb --quiet ../03_annotation/$f1.gbk.gz > virulence_out.tsv

	cd ../

	# STEP 07: Secondary metabolites

	echo
	echo 'SCREENING FOR SECONDARY METABOLITES PRODUCTION IN' $f1

	cp 03_annotation/$f1.gbk.gz .
	gunzip $f1.gbk.gz
	run_antismash $f1.gbk 07_secondary_metabolites --genefinding-tool none

	# cleanup
	rm $f1.gbk
	mv 07_secondary_metabolites/$f1/* 07_secondary_metabolites
	rm -r 07_secondary_metabolites/$f1

	# Make the zip file readable for the ftp account
	setfacl -m u:ftp_access:r 07_secondary_metabolites/$f1.zip

	# STEP 08: GTs and GHS

	echo
	echo 'SCREENING FOR GHs AND GTs IN' $f1

	mkdir -p 08_GTs_GHs
	cd 08_GTs_GHs

	cp ../03_annotation/$f1.faa.gz .
	gunzip $f1.faa.gz

	hmmscan --cpu $THREADS \
	  --domtblout GH_GT_hits.tsv \
	 /media/harddrive/seqdata_wgs/data/dbCAN/dbCAN-fam-HMMs_converted.txt $f1.faa > hmmscan.log
	/media/harddrive/seqdata_wgs/src/hmmscan-parser.sh GH_GT_hits.tsv > GH_GT_parsed.tsv

	cd ../

	# STEP 09: Other relevant genes

        echo
        echo 'SCREENING FOR OTHER RELEVANT GENES' $f1

        mkdir -p 09_other_genes
        cd 09_other_genes
	cp ../03_annotation/$f1.faa.gz ./
	gunzip $f1.faa.gz

	FILES=/media/harddrive/seqdata_wgs/data/other_genes_of_interest/*hmm
	for f in $FILES
	do
	  filename="${f##*/}"
	  filename_wo_extension="${filename%%.*}"
	  echo "Processing $filename_wo_extension"

	   hmmscan --cpu $THREADS \
		--domtblout ${filename_wo_extension}_hits.tsv \
		$f $f1.faa > hmscan_$filename_wo_extension.log
           /media/harddrive/seqdata_wgs/src/hmmscan-parser.sh ${filename_wo_extension}_hits.tsv > ${filename_wo_extension}_parsed.tsv

	done

	rm ../08_GTs_GHs/$f1.faa

	cd ../

	# Print metadata file
	echo -e "$f1\t$f5\t$f6\t$f7" > ${f1}_metadata.tsv

	# Create Genome Report
	Rscript /media/harddrive/seqdata_wgs/src/launch_rmarkdown_script.R $(pwd)

	# Cleanup
	rm prokka.out
	cd ../

done < <(tail -n +2 $INPUT_FILE)

# Do overall genome analysis
#Rscript -e '
#  rmarkdown::render(
#	  "../scripts/generate_report_all_genomes.Rmd",
#		output_file = "/media/harddrive/seqdata_wgs/genomes/20191021_genome_report.html"
#	)
#'
#
