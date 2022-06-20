CONDA_dir=`dirname $(which conda)`"/../"
LGP_outdir="/media/hdd/LGP/"


# Initialize conda
if [ -e "$CONDA_dir/etc/profile.d/conda.sh" ] ; then
    source "$CONDA_dir/etc/profile.d/conda.sh"
fi
