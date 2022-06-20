###############################################################################
# All LGP function names (and variables) start with LGP, for clarity
function LGP_style() {
    # We always give meaningful names to parameters, if relevant, using local variables
    local apple="$1" # We always surround variables with quotes
    local pear="$2"
}

###############################################################################

function LGP_version() {
    local file="$1"
    local timestamp=`date -r "$file" '+%Y.%m.%d.%H%M'`
    local md5=`md5sum "$file" | cut -d\   -f1`
    echo "${timestamp}_${md5}"
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

function LGP_prepare(){
    local genomename="$1"
    local name="$2"
    local version="$3"
    local force="$4"
    
    LGP_message "STARTING: $name ($version) for $genomename"
    
    local path=`realpath "$LGP_outdir/$genomename/$name/$version"`
    
    if [ -d "$path" ]; then
        LGP_warn "'$path' already exists. You may overwrite a previous analysis."
        if [ "$force" -eq 0 ]; then
            for i in `seq 10`; do
                wrn=`LGP_warn "Press ctrl+c to cancel this" 2>&1`
                echo -en "\r$wrn ($((10-i)))..." >&2
                sleep 1
                if [ ! $? -eq 0 ] ; then # Make sure we catch an escape!
                    exit 2
                fi
            done
            echo "" >&2
        fi
    fi
    
    mkdir -p "$path"
    
    echo "$path"
    
}

###############################################################################

function LGP_existsorfail(){
    local path="$1"
    local exitcode="$2"
    
    if [ ! -e "$path" ]; then
        LGP_error "'$path' does not exist"
        exit $exitcode
    fi
}

###############################################################################

function LGP_message(){
    local message="$1"
    echo "[LGP] `date` $message" >&2
}

function LGP_warn(){
    local message="$1"
    echo "[LGP] `date` Warning: $message" >&2
}

function LGP_error(){
    local message="$1"
    echo "[LGP] `date` Error: $message" >&2
}