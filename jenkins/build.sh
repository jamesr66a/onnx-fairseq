#!/bin/bash

set -ex

scripts_dir=$(dirname $(realpath "${BASH_SOURCE[0]}"))
source "$scripts_dir/common"

[[ $PYTHON_VERSION == 3.6 ]] || die "Need python3.6 to run onnx-fairseq"

# venv
venv_dir="$build_cache_dir/virtualenvs/venv3.6"
mkdir -p $venv_dir
rm -rf $venv_dir && python3.6 -m venv $venv_dir
source $venv_dir/bin/activate
pip install -U setuptools pip
pip install pyyaml numpy protobuf future

src_dir="$workdir/src"

# pytorch
cd "$src_dir/pytorch"
NO_CUDA=1 python setup.py build develop

# caffe2
c2_install_dir="$build_cache_dir/caffe2"
rm -rf $c2_install_dir && mkdir -p $c2_install_dir
cd "$src_dir/caffe2"
mkdir -p build
cd build
cmake \
    -DPYTHON_INCLUDE_DIR="$(python -c 'from distutils import sysconfig; print(sysconfig.get_python_inc())')" \
    -DPYTHON_LIBRARY=$(python -c "import distutils.sysconfig as sysconfig; print(sysconfig.get_config_var('LIBDIR'))")/libpython3.6m.dylib \
    -DCMAKE_INSTALL_PREFIX:PATH="$c2_install_dir" \
    -DBUILD_TEST=OFF \
    -DUSE_CUDA=OFF \
    -DUSE_ATEN=ON \
    ..
make -j16
make install

# onnx
cd "$src_dir/onnx"
pip install -e .

# onnx-caffe2
cd "$src_dir/onnx-caffe2"
pip install -e .

# fairseq
cd "$src_dir/fairseq-py"
python setup.py build develop
