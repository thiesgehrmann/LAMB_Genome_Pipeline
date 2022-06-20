###############################################################################
# All LGP function names (and variables) start with LGP, for clarity
function LGP_style() {
    # We always give meaningful names to parameters, if relevant, using local variables
    local apple="$1" # We always surround variables with quotes
    local pear="$2"
}

###############################################################################

function LGP_md5() {
    local file="$1"
    local timestamp=`date -r "$file" '+%Y.%m.%d.%H%M'`
    local md5=`md5sum "$file" | cut -d\   -f1`
    echo "$md5_$timestamp"
}

###############################################################################
 
function LGP_conda(){
    local envname="$1"
    local yaml="$2"
    
    if [ -z `conda env list | cut -d\  -f1 | grep "$envname"` ]; then
        conda env create -n "$envname" --file "$yaml" &> /dev/null
    fi
    
    conda activate "$envname"

}

###############################################################################
