#!/usr/bin/env bash

###############################################################################
# Boilerplate code
LGPS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
for lgpc in `ls "$LGPS_DIR/../00_common/" | grep '[.]sh$' `; do source "$LGPS_DIR/../00_common/$lgpc"; done;
LGPS_name=`basename "$LGPS_DIR"`
LGPS_version=`LGP_version "$LGPS_DIR/$0"`


###############################################################################
# LAMB Genome Pipeline script

function usage(){
    echo "LAMB Genome Pipeline ($LGPS_name)"
    echo "Version: $LGPS_version"
    echo "Usage: $0 [options] <GENOMENAME> <file1> <file2> <file3>"
    echo "  Options:"
    echo "    -t|--threads  : Number of threads to use (default 1)"
    echo "    --noconda:    : Do not use (default yes)"
    echo "    --force       : Do not give opportunity to cancel run if previous directory exists (default no)"
    echo "  Inputs:"
    echo "    GENOMENAME : The name of this genome (e.g. AMBV666)"
    echo "    file1 : File path to file1."
    echo "    file2 : File path to file2."
    echo "    file3 : File path to file3."
}

###############################################################################
# Process options and inputs

ARGS=$(getopt -o 't:' --long 'threads:,noconda,force' -- "$@") || exit
eval "set -- $ARGS"

threads=1
noconda=0
force=0

while true; do
    case $1 in
      (-t|--threads)
            threads=$2; shift 2;;
      (--noconda)
            noconda=1; shift 1;;
      (--force)
            force=1; shift 1;;
      (--)  shift; break;;
      (*)   usage $0; exit 1;;           # error
    esac
done

#############################
# Deal with file inputs

remaining=("$@")

if [ ! "${#remaining[@]}" -eq 4 ]; then
    usage $0
    exit 1
fi

genomename=${remaining[0]}
file1=`realpath "${remaining[1]}"`
file2=`realpath "${remaining[2]}"`
file3=`realpath "${remaining[3]}"`

# Verify that the input files exist
LGP_existsorfail "$file1" 1
LGP_existsorfail "$file2" 1
LGP_existsorfail "$file3" 1

###############################################################################
# Initialize the output folder
outdir=`LGP_prepare "$genomename" "$LGPS_name" "$LGPS_version" "$force"`

# Load conda environment (if necessary)
if [ "$noconda" -eq 0 ]; then
    LGP_message "Loading conda environment"
    LGP_conda "mda" "$LGPS_DIR/conda.yml" # Use an existing conda environment for testing
    #LGP_conda "LGPS_${LGPS_name}" "$LGPS_DIR/conda.yml" # Use this when ready
fi


###############################################################################
# Program code


# Perform the operations
cp "$file1" "$outdir/file1"
cp "$file2" "$outdir/file2"
cp "$file3" "$outdir/file3"

###############################################################################
# Wrap up
LGP_message "Completed $LGPS_name"