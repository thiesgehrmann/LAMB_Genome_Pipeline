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
    
    if [ -z `which conda` ]; then
        LGP_warn "Conda not found. Will continue without."
    else
        if [ -z `conda env list | cut -d\  -f1 | grep "$envname"` ]; then
            conda env create -n "$envname" --file "$yaml" &> /dev/null
        fi
        conda activate "$envname"
    fi
}

###############################################################################

LGP_STATUS_RUNNING="-1"
LGP_STATUS_COMPLETED="0"
LGP_STATUS_FAILED="1"

function LGP_init(){
    local outdir="$1"
    local genomename="$2"
    local name="$3"
    local version="$4"
    local force="$5"
    local command="$6"
    
    LGP_message "INITIALIZING: $name ($version) for $genomename"
    
    local path="$outdir/$genomename/$name/$version"
    
    if [ -e "$path" ]; then
        status=`LGP_status "$path"`
        if [ "$status" == "$LGP_STATUS_COMPLETED" ] || [ "$status" == "$LGP_STATUS_RUNNING" ]; then

            LGP_warn "'$path' is marked as COMPLETED or RUNNING. You will overwrite a previous/running analysis."
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
    fi
    
    mkdir -p "$path"
    if [ ! "$?" -eq 0 ]; then
        LGP_error "Could not create '$path'. Permission denied."
        exit 2
    fi
    
    echo "$LGP_STATUS_RUNNING" > "$path/status"
    
    echo "
{
    'started': '`date`',
    'user': '`whoami`', 
    'name': '$name', 
    'version: '$version',
    'genomename' : '$genomename'
    'command': '$command',
    'pwd' : '`pwd`',
    'env' : '`env`'
}
    " > "$path/runinfo.json"
    
    echo "$path"
    
}

function LGP_verify(){
    local path="$1"
    LGP_verify "$path"
    
    if [ ! -d "$path" ]; then
        LGP_error "The specified path is not a valid LGP path."
        exit 2
    fi
    
    status=`cat "$path/status"`
    status_ok=0
    
    case "$status" in
      ($LGP_STATUS_RUNNING|$LGP_STATUS_COMPLETED|$LGP_STATUS_FAILED)
            status_ok=1;;
    esac
    
    if [ ! "$status_ok" -eq 1 ]; then
        LGP_error "The specified path has been corrupted. Please run:"
        LGP_error "     rm '$path'"
        exit 2
    fi
}

function LGP_complete(){
    local path="$1"
    
    echo "$LGP_STATUS_COMPLETED" > "$path/status"
    LGP_message "COMPLETED. Output in '$path'"
    exit 0
}

function LGP_fail(){
    local path="$1"
    LGP_verify "$path"
    
    echo "$LGP_STATUS_FAILED" > "$path/status"
    exit 1
}
    
    
function LGP_status(){
    local path="$1"
    

    status=`cat "$path/status"`
    case "$status" in
      ($LGP_STATUS_RUNNING|$LGP_STATUS_COMPLETED|$LGP_STATUS_FAILED)
            echo "$status";;
      (*)
          echo "UNKNOWN";;
    esac

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
    echo "[LGP] (`date`) $message" >&2
}

function LGP_warn(){
    local message="$1"
    echo "[LGP] (`date`) Warning: $message" >&2
}

function LGP_error(){
    local message="$1"
    echo "[LGP] (`date`) Error: $message" >&2
}