ARG DEBIAN_VERSION=12
FROM debian:${DEBIAN_VERSION}-slim
LABEL maintainer="George McCabe <mccabe@ucar.edu>"

ARG MET_COMPILE_SCRIPT_BRANCH=feature_baseimage_30_py3.12.0
ARG MET_TAR_FILE_VERSION_NAME=met-base-v3.4

ENV PYTHON_VER=3.12.0

ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV FC=/usr/bin/gfortran
ENV F77=/usr/bin/gfortran

ENV GSFONT_URL=https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/ghostscript-fonts-std-8.11.tar.gz
ENV MET_FONT_DIR=/usr/local/share/met/fonts

WORKDIR /met

RUN \
    echo "Set up the environment for interactive bash shell" &&\
    echo export MET_BASE=/usr/local/share/met >> /root/.bashrc &&\
    echo export MET_FONT_DIR=/usr/local/share/met/fonts >> /root/.bashrc &&\
    echo export RSCRIPTS_BASE=/usr/local/share/met/Rscripts >> /root/.bashrc \
 && echo "Set soft limit to unlimited to prevent GRIB2 seg faults" &&\
    echo ulimit -S -s unlimited >> /root/.bashrc \
 && echo "Installing required system tools" &&\
    apt update && apt -y upgrade &&\
    apt install -y automake bison build-essential cmake curl emacs flex \
     gfortran git imagemagick less libbz2-dev libc6-dev libcurl4-gnutls-dev \
     libffi-dev libgdbm-dev libjpeg-dev libncursesw5-dev libpixman-1-dev \
     libreadline-dev libsqlite3-dev libssl-dev libtiff-dev m4 sqlite3 tk-dev \
     unzip vim wget zlib1g-dev \
 && echo "Clean cache after installing system packages" &&\
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
 && echo "Downloading GhostScript fonts from ${GSFONT_URL} into /usr/local/share/met" &&\
    mkdir -p /usr/local/share/met &&\
    curl -SL ${GSFONT_URL} | tar zxC /usr/local/share/met \
 && echo "Fix rules for ghostscript files in convert" &&\
    echo "See: https://en.linuxportal.info/tutorials/troubleshooting/how-to-fix-errors-from-imagemagick-imagick-conversion-system-security-policy" &&\
    sed -i 's/policy domain="coder" rights="none" pattern="PS/policy domain="coder" rights="read | write" pattern="PS/g' /etc/ImageMagick-6/policy.xml &&\
    sed -i 's/policy domain="coder" rights="none" pattern="EPS"/policy domain="coder" rights="read | write" pattern="EPS"/g' /etc/ImageMagick-6/policy.xml &&\
    sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read | write" pattern="PDF"/g' /etc/ImageMagick-6/policy.xml &&\
    sed -i 's/policy domain="coder" rights="none" pattern="XPS"/policy domain="coder" rights="read | write" pattern="XPS"/g' /etc/ImageMagick-6/policy.xml \
 && echo "Install Python from source" &&\
    wget https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz &&\
    tar xzf Python-${PYTHON_VER}.tgz &&\
    (cd Python-${PYTHON_VER} &&\
    ./configure --enable-optimizations --enable-shared LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" &&\
    make -j `nproc` &&\
    make install) &&\
    ln -s /usr/local/bin/python3 /usr/local/bin/python \
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
    BLDOPTS="--global-option=build_ext --global-option=\"-R/usr/local/lib\" --global-option=\"-L/usr/local/lib\"" &&\
    export HDF5_DIR=/usr/local/ &&\
    export NETCDF4_DIR=/usr/local/ &&\
    python3 -m pip install --upgrade pip &&\
    python3 -m pip install ${BLDOPTS} numpy==2.2.2 xarray==2025.1.2 netCDF4==1.7.2 pyyaml==6.0.2 scipy==1.15.1 \
 && echo "Running linker configuration" &&\
    ldconfig
