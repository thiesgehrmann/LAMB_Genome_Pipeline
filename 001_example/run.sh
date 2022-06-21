#!/usr/bin/env bash
# LAMB Genome Pipeline script

###############################################################################
###############################################################################
################################ DO NOT TOUCH #################################
###############################################################################
###############################################################################

# Boilerplate initialize code
LGPS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
for lgpc in `ls "$LGPS_DIR/../00_common/" | grep '[.]sh$' `; do source "$LGPS_DIR/../00_common/$lgpc"; done;
LGPS_name=`basename "$LGPS_DIR"`
LGPS_version=`LGP_version "$LGPS_DIR/$0"`
command="$0 $@"


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++ MODIFY HERE #++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# Define the usage function
function usage(){
    echo "LAMB Genome Pipeline ($LGPS_name)"
    echo "Version: $LGPS_version"
    echo "Usage: $0 [options] <GENOMENAME> <file1> <file2> <file3>"
    echo "  Options:"
    echo "    -t|--threads  : Number of threads to use (default 1)"
    echo "    --noconda:    : Do not use (default yes)"
    echo "    --force       : Do not give opportunity to cancel run if previous directory exists (default no)"
    echo "    --outdir      : Use this location instead of the standard LGP output (default $LGP_outdir)"
    echo "  Inputs:"
    echo "    GENOMENAME : The name of this genome (e.g. AMBV666)"
    echo "    file1 : File path to file1."
    echo "    file2 : File path to file2."
    echo "    file3 : File path to file3."
}

###############################################################################
# Process options and inputs

ARGS=$(getopt -o 't:' --long 'threads:,noconda,force,outdir:' -- "$@") || exit
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
        (--outdir)
          export LGP_outdir=`realpath "$2"`; shift 2;;
        (--)  shift; break;;
        (*)   usage $0; exit 1;;           # error
    esac
done

###############################################################################
###############################################################################
################################ DO NOT TOUCH #################################
###############################################################################
###############################################################################
# Deal with file inputs

remaining=("$@") # Get the rest of the parmeters that are not options

if [ ! "${#remaining[@]}" -eq 4 ]; then
    usage $0
    exit 1
fi

genomename=${remaining[0]}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++ MODIFY HERE #++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

file1=`realpath "${remaining[1]}"`
file2=`realpath "${remaining[2]}"`
file3=`realpath "${remaining[3]}"`

# Verify that the input files exist
LGP_existsorfail "$file1" 1
LGP_existsorfail "$file2" 1
LGP_existsorfail "$file3" 1

###############################################################################
###############################################################################
################################ DO NOT TOUCH #################################
###############################################################################
###############################################################################
# Initialize the output folder
path=`LGP_init "$LGP_outdir" "$genomename" "$LGPS_name" "$LGPS_version" "$force" "$command"`


# Load conda environment (if necessary)
if [ "$noconda" -eq 0 ]; then
    LGP_message "Loading conda environment"
    LGP_conda "mda" "$LGPS_DIR/conda.yml" # Use an existing conda environment for testing
    #LGP_conda "LGPS_${LGPS_name}" "$LGPS_DIR/conda.yml" # Use this when ready
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++ MODIFY HERE #++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Program code


# Perform the operations
cp "$file1" "$path/file1"
status1="$?" # KEEP THE RETURN VALUE OF THE ANALYSIS

cp "$file2" "$path/file2"
status2="$?"

cp "$file3" "$path/file3"
status3="$?"

status=$((status1 + status2 + status3))


###############################################################################
###############################################################################
################################ DO NOT TOUCH #################################
###############################################################################
###############################################################################

# Wrap up
if [ "$status" -eq 0 ]; then
    LGP_complete "$path"
else
    LGP_fail "$path"
fi

###############################################################################