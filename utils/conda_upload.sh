#!/bin/bash

# file: conda_upload.sh
# description: builds and uploads cyclus projects (cyclus, cycamore, and cymetric) to binstar
# for a release

set -e

usage() {

cat <<EOF

Script to upload compiled binaries of Cyclus, Cycamore, and Cymetric to binstar as part of the release process.

usage: $0 <version>

        version : the version string (e.g., X.Y.Z) to with which this package will be labeled.

The following environment variables must be set for this script to function:

     CYCLUS_DIR : Environment variable CYCLUS_DIR must be set to the cyclus repository directory.
   CYCAMORE_DIR : Environment variable CYCAMORE_DIR must be set to the cycamore repository directory.
   CYMETRIC_DIR : Environment variable CYMETRIC_DIR must be set to the cymetric repository directory.

EOF

}

die() {

    echo -n >&2 "ERROR: "
    echo >&2 "$@"
    usage
    exit 1

}

# special behavior for macosx
sed_i() {
    if [[ "`uname`" == "Linux" ]]; then
	sed -i  "$1" "$2";
    else
    	sed -i '' "$1" "$2";
    fi
}

upload_pkg() {

    pkg_name=$1 
    version=$2

    git checkout $version
    cp conda-recipe/meta.yaml conda-recipe/.orig.meta.yaml
    sed_i  "s/0.0/$version/g" conda-recipe/meta.yaml
    sed_i  "s/nightly/0/g" conda-recipe/meta.yaml
    conda build --no-test conda-recipe
    binstar upload --force -u cyclus $CONDA/conda-bld/linux-64/$pkg_name-$version-0.tar.bz2
    mv conda-recipe/.orig.meta.yaml conda-recipe/meta.yaml

}


# check input
CYCLUS=${CYCLUS_DIR?"Environment variable CYCLUS_DIR must be set to the cyclus repository directory."}
CYCAMORE=${CYCAMORE_DIR?"Environment variable CYCAMORE_DIR must be set to the cycamore repository directory."}
CYMETRIC=${CYMETRIC_DIR?"Environment variable CYMETRIC_DIR must be set to the cymetric repository directory."}
[ "$#" -eq 1 ] || die "Must provide the version (e.g., X.X.X) as an argument"
VERSION=$1

HERE=$PWD
echo "Conda updating for Cyclus stack verison $VERSION"

mkdir _build
cd _build
export CONDA="$PWD/miniconda"
export PATH="$CONDA/bin:$PATH"
export PYTHONPATH="$CONDA"
wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -p $CONDA
hash -r
conda config --set always_yes yes --set changeps1 no
conda config --add channels pyne
conda config --add channels cyclus
conda update -q conda
conda install conda-build jinja2 setuptools binstar patchelf nose
# Useful for debugging any issues with conda
conda info -a
cd ..

cd $CYCLUS
upload_pkg "cyclus" "$VERSION"

cd $CYCAMORE
upload_pkg "cycamore" "$VERSION"

cd $CYMETRIC
upload_pkg "cymetric" "$VERSION"

cd $HERE
rm -rf _build
