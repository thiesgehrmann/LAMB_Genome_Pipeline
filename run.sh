#!/usr/bin/env bash

###############################################################################
# Boilerplate code
LGPS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
for lgpc in `find "$LGPS_DIR/00_common/" | grep '[.]sh$' `; do source "$lgpc"; done;
LGPS_version=`LGP_version "$LGPS_DIR/$0"`

# Load conda environment (if necessary)
LGP_conda "mda" "$LGPS_DIR/conda.yml"


###############################################################################
# LAMB Genome Pipeline script

function usage(){
    echo "LAMB Genome Pipeline (Step XXX)"
    echo "Version: $LGPS_version"
    echo "Usage: $0 [options] <GENOMENAME> <file1> <file2> <file3>"
    echo "  Options:"
    echo "    -t|--threads  : Number of threads to use (default 1)"
    echo "  Inputs:"
    echo "    GENOMENAME : The name of this genome (e.g. AMBV)"
    echo "    file1 : File path to file1."
    echo "    file2 : File path to file2."
    echo "    file3 : File path to file3."

}

###############################################################################
# Process options and inputs

ARGS=$(getopt -o 't:' --long 'threads:' -- "$@") || exit
eval "set -- $ARGS"

threads=1

while true; do
    case $1 in
      (-t|--threads)
            threads=$2; shift 2;;
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

genomename=${remaining[1]}
file1=${remaining[2]}
file2=${remaining[3]}
file3=${remaining[4]}

###############################################################################
# Program code

cp "$file1" "$LGP_outdir/"