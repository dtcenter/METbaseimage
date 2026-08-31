ARG BASE_REGISTRY=docker.io
ARG BASE_IMAGE=debian
ARG BASE_TAG=12-slim
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="George McCabe <mccabe@ucar.edu>"

ARG MET_COMPILE_SCRIPT_BRANCH=develop
ARG MET_TAR_FILE_VERSION_NAME=met-base-v3.5

ENV PYTHON_VER=3.14.4

# set env vars needed to install MET with Python Embedding support
ENV MET_PYTHON_BIN_EXE=/usr/local/bin/python3
ENV MET_PYTHON_CC="-I/usr/local/include/python3.14"
ENV MET_PYTHON_LD="-L/usr/local/lib -lpython3.14 -ldl -lm"

ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV FC=/usr/bin/gfortran
ENV F77=/usr/bin/gfortran

ENV GSFONT_URL=https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/ghostscript-fonts-std-8.11.tar.gz
ENV MET_FONT_DIR=/usr/local/share/met/fonts

WORKDIR /met

#
# - Remove packages containing Critical CVEs:
#   NAME              INSTALLED               FIXED IN    TYPE VULNERABILITY  SEVERITY EPSS % RISK
#   zlib1g-dev        1:1.2.13.dfsg-1         (won't fix) deb  CVE-2023-45853 Critical 70.89  0.6
#   libopenexr-3-1-30 3.1.5-5                 (won't fix) deb  CVE-2023-5841  Critical 70.03  0.6
#   libaom3           3.6.0-1+deb12u1         (won't fix) deb  CVE-2023-6879  Critical 37.08  0.1
#   libxml2           2.9.14+dfsg-1.3~deb12u2 (won't fix) deb  CVE-2025-49794 Critical 23.45  < 0.1
#   libxml2           2.9.14+dfsg-1.3~deb12u2 (won't fix) deb  CVE-2025-49796 Critical 18.40  < 0.1
#   libarchive13      3.6.2-1+deb12u2         (won't fix) deb  CVE-2025-5914  Critical 10.77  < 0.1
#
# - Install imagemagick after removal because it was removed as a dependency.
#   Must install from source with some features like xml excluded because version from apt re-installs problematic
#   packages that contain critical CVEs.

RUN \
    echo "Set up the environment for interactive bash shell" &&\
    echo export MET_BASE=/usr/local/share/met >> /root/.bashrc &&\
    echo export MET_FONT_DIR=/usr/local/share/met/fonts >> /root/.bashrc &&\
    echo export RSCRIPTS_BASE=/usr/local/share/met/Rscripts >> /root/.bashrc \
 && echo "Set soft limit to unlimited to prevent GRIB2 seg faults" &&\
    echo ulimit -S -s unlimited >> /root/.bashrc \
 && echo "Installing required system tools" &&\
    apt update && apt -y upgrade &&\
    apt install -y automake bison build-essential cmake curl equivs flex \
     gfortran ghostscript git less libbz2-dev libc6-dev libcurl4-gnutls-dev \
     libffi-dev libgdbm-dev libjpeg-dev libncursesw5-dev libopenblas-dev \
     libpixman-1-dev libreadline-dev libssl-dev libtiff-dev m4 \
     tk-dev unzip vim wget \
 && echo "Clean cache after installing system packages" &&\
    apt clean \
 && echo "Downloading GhostScript fonts from ${GSFONT_URL} into /usr/local/share/met" &&\
    mkdir -p /usr/local/share/met &&\
    curl -SL ${GSFONT_URL} | tar zxC /usr/local/share/met \
 && echo "Install Python from source" &&\
    wget https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz &&\
    tar xzf Python-${PYTHON_VER}.tgz &&\
    (cd Python-${PYTHON_VER} &&\
    ./configure --enable-optimizations --enable-shared --disable-test-modules \
      LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" &&\
    make -j `nproc` &&\
    make install) &&\
    ln -s /usr/local/bin/python3 /usr/local/bin/python &&\
    rm -rf Python-${PYTHON_VER}* \
 && echo "Compile the MET libraries" &&\
    echo "Pulling compilation script from MET branch ${MET_COMPILE_SCRIPT_BRANCH}" &&\
    wget https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.${MET_TAR_FILE_VERSION_NAME}.tgz &&\
    wget https://raw.githubusercontent.com/dtcenter/MET/${MET_COMPILE_SCRIPT_BRANCH}/internal/scripts/installation/compile_MET_all.sh &&\
    wget https://raw.githubusercontent.com/dtcenter/MET/${MET_COMPILE_SCRIPT_BRANCH}/internal/scripts/environment/development.docker &&\
    tar -zxf tar_files.${MET_TAR_FILE_VERSION_NAME}.tgz &&\
    export SKIP_MET=TRUE &&\
    chmod +x compile_MET_all.sh &&\
    ./compile_MET_all.sh development.docker \
 && echo "Installing required Python packages" &&\
    python3 -m pip install --upgrade pip setuptools wheel Cython meson-python &&\
    (export HDF5_DIR=/usr/local/ &&\
     export NETCDF4_DIR=/usr/local/ &&\
     export CPPFLAGS="-I/usr/local/include" &&\
     export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" &&\
     python3 -m pip install --upgrade pip &&\
     python3 -m pip install --no-binary :all: \
       netCDF4~=1.7.4 \
       numpy~=2.4.6 \
       pandas~=3.0.3 \
       python-dateutil~=2.9.0.post0 \
       pyyaml~=6.0.3 \
       scipy~=1.17.1 \
       six~=1.17.0 \
       xarray~=2026.1.0 \
    ) \
 && echo "Running linker configuration" &&\
    ldconfig \
 && echo "Remove packages with CVEs" &&\
    apt remove -y zlib1g-dev libopenexr-3-1-30 libaom3 libxml2 libarchive13 \
 && echo "Building ImageMagick without XML support" &&\
    wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.2-0.tar.gz &&\
    tar xzf 7.1.2-0.tar.gz &&\
    (cd ImageMagick-7.1.2-0 &&\
    ./configure \
    --without-xml \
    --without-dps \
    --without-djvu \
    --without-fftw \
    --without-fpx \
    --without-gvc \
    --without-jbig \
    --without-lqr \
    --without-lzma \
    --without-openexr \
    --without-pango \
    --without-rsvg \
    --without-x \
    --disable-shared \
    --enable-static &&\
    make -j $(nproc) &&\
    make install &&\
    ldconfig)
