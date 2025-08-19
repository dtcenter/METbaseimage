ARG DEBIAN_VERSION=12
FROM debian:${DEBIAN_VERSION}-slim
LABEL maintainer="George McCabe <mccabe@ucar.edu>"

ARG MET_COMPILE_SCRIPT_BRANCH=main_v12.1
ARG MET_TAR_FILE_VERSION_NAME=met-base-v3.4

#
# CVE-2025-4517
#   Switch from Python 3.12.0 to 3.12.11
#
ENV PYTHON_VER=3.12.11

ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV FC=/usr/bin/gfortran
ENV F77=/usr/bin/gfortran

ENV GSFONT_URL=https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/ghostscript-fonts-std-8.11.tar.gz
ENV ZLIB_URL=https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/zlib-1.3.1.tar.gz
ENV SQLITE3_URL=https://www.sqlite.org/2025/sqlite-autoconf-3500300.tar.gz
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
    apt install -y automake bison build-essential cmake curl flex \
     gfortran ghostscript git less libbz2-dev libc6-dev libcurl4-gnutls-dev \
     libffi-dev libgdbm-dev libjpeg-dev libncursesw5-dev libopenblas-dev \
     libpixman-1-dev libreadline-dev libssl-dev libtiff-dev m4 \
     tk-dev unzip vim wget \
 && echo "Clean cache after installing system packages" &&\
    apt clean \
 && echo "Dowloading zlib from ${ZLIB_URL}" &&\
    wget ${ZLIB_URL} &&\
    tar xzf zlib-1.3.1.tar.gz &&\
    (cd zlib-1.3.1 &&\
    ./configure --enable-shared &&\
    make -j `nproc` &&\
    make install) \
 && echo "Downloading and installing sqlite3 from ${SQLITE3_URL}" &&\
    wget ${SQLITE3_URL} &&\
    filename=$(basename ${SQLITE3_URL}) &&\
    tar xzf ${filename} &&\
    (cd ${filename%%.*} && ./configure && make -j $(nproc) && make install) \
 && echo "Downloading GhostScript fonts from ${GSFONT_URL} into /usr/local/share/met" &&\
    mkdir -p /usr/local/share/met &&\
    curl -SL ${GSFONT_URL} | tar zxC /usr/local/share/met \
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
#
RUN apt remove -y zlib1g-dev libopenexr-3-1-30 libaom3 libxml2 libarchive13 \
 && echo "Building ImageMagick without XML support" &&\
    wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.2-0.tar.gz &&\
    tar xzf ImageMagick-7.1.2-0.tar.gz &&\
    (cd ImageMagick-7.1.2-0 &&\
    ./configure \
    --without-xml \
    --without-dps \
    --without-djvu \
    --without-fftw \
    --without-fpx \
    --without-gslib \
    --without-gvc \
    --without-jbig \
    --without-jpeg \
    --without-lcms \
    --without-lqr \
    --without-lzma \
    --without-openexr \
    --without-pango \
    --without-rsvg \
    --without-webp \
    --without-x \
    --disable-shared \
    --enable-static &&\
    make -j $(nproc) &&\
    make install &&\
    ldconfig) \
 && echo "Fix rules for ghostscript files in convert" &&\
    echo "See: https://en.linuxportal.info/tutorials/troubleshooting/how-to-fix-errors-from-imagemagick-imagick-conversion-system-security-policy" &&\
    sed -i 's/policy domain="coder" rights="none" pattern="PS/policy domain="coder" rights="read | write" pattern="PS/g' /usr/local/etc/ImageMagick-7/policy.xml &&\
    sed -i 's/policy domain="coder" rights="none" pattern="EPS"/policy domain="coder" rights="read | write" pattern="EPS"/g' /usr/local/etc/ImageMagick-7/policy.xml &&\
    sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read | write" pattern="PDF"/g' /usr/local/etc/ImageMagick-7/policy.xml &&\
    sed -i 's/policy domain="coder" rights="none" pattern="XPS"/policy domain="coder" rights="read | write" pattern="XPS"/g' /usr/local/etc/ImageMagick-7/policy.xml \
 && echo "Install Chrome dependencies that are not found in slim OS - needed by plotly/kaleido for METplotpy" &&\
    apt install -y libasound2 libatk-bridge2.0-0 libcairo2 libcups2 libgbm1 libnss3 libpango-1.0-0 \
                   libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 \
 && echo "Remove libxml2 and libsqlite3-0 again because they were added again from chrome dependencies" &&\
    apt remove -y libxml2 libsqlite3-0 &&\
    apt clean
