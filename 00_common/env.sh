CONDA_dir=`dirname $(which conda)`"/../"
CONDA_dir="/media/ssdsata/thies/miniconda3/"
LGP_outdir="/media/hdd/LGP/"

LGP_WARNING_TIME=10


# Initialize conda
if [ -e "$CONDA_dir/etc/profile.d/conda.sh" ] ; then
    source "$CONDA_dir/etc/profile.d/conda.sh"
fi
