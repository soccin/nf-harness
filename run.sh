#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

export NXF_SINGULARITY_CACHEDIR=/rtsess01/compute/juno/bic/ROOT/opt/singularity/cachedir_socci
export TMPDIR=/scratch/socci
export PATH=$SDIR/bin:$PATH

hash nextflow 2>/dev/null || {
    echo -en >&2 "\n\n   nextflow not installed. Need to install in\n      adagio/bin\n"
    echo -en >&2 "\n   See 'docs/installation.md' for more info\n\n"
    exit 1;
}

set -eu

if [ "$#" -ne "1" ]; then
    echo
    echo usage: $(basename $(dirname $0))/$(basename $0) ARG1
    echo
    exit
fi

#
# Check if in backgroup or forground
#
# https://unix.stackexchange.com/questions/118462/how-can-a-bash-script-detect-if-it-is-running-in-the-background
#

case $(ps -o stat= -p $$) in
  *+*) ANSI_LOG="true" ;;
  *) ANSI_LOG="false" ;;
esac

ODIR="out"
mkdir -p $ODIR

#:BEGIN
echo nextflow run $SDIR/pipeline-dir/main.nf \
    -ansi-log $ANSI_LOG \
    -resume \
    -profile singularity \
    -c $SDIR/conf/lsf_juno.config \
    ...
#:END

#
# Dump version and run info
#

GTAG=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --long --tags --dirty="-UNCOMMITED" --always)
GURL=$(git --git-dir=$SDIR/.git --work-tree=$SDIR config --get remote.origin.url)

mkdir -p $ODIR/runlog
cat <<-END_VERSION > $ODIR/runlog/cmd.sh.log
Script: $0 $*

GURL: $GURL
GTAG: $GTAG
PWD: $PWD

SDIR=$SDIR
NXF_SINGULARITY_CACHEDIR=$NXF_SINGULARITY_CACHEDIR
TMPDIR=$TMPDIR
ANSI_LOG=$ANSI_LOG

END_VERSION

cat $0 | sed -n '/^#:BEGIN/,/^#:END/p' >> $ODIR/runlog/cmd.sh.log
