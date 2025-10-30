ARG DEBIAN_VERSION=12
FROM debian:${DEBIAN_VERSION}-slim
LABEL maintainer="George McCabe <mccabe@ucar.edu>"

#
# Define the compilers
#
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV FC=/usr/bin/gfortran
ENV F77=/usr/bin/gfortran

#
# CVE-2022-37454
#   Switch from Python 3.10.4 to 3.10.18
#
ENV PYTHON_VER=3.10.18

ENV GSFONT_URL=https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/ghostscript-fonts-std-8.11.tar.gz
ENV ZLIB_URL=https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/zlib-1.3.1.tar.gz
ENV SQLITE3_URL=https://www.sqlite.org/2025/sqlite-autoconf-3500300.tar.gz

#
# Set up the environment for interactive bash shell
# Set soft limit to unlimited to prevent GRIB2 seg faults
#
RUN echo export MET_BASE=/usr/local/share/met >> /root/.bashrc \
 && echo export MET_FONT_DIR=/usr/local/share/met/fonts >> /root/.bashrc \
 && echo export RSCRIPTS_BASE=/usr/local/share/met/Rscripts >> /root/.bashrc \
 && echo ulimit -S -s unlimited >> /root/.bashrc

ENV MET_FONT_DIR=/usr/local/share/met/fonts

#
# Install required system tools
#
RUN apt update && apt -y upgrade \
 && apt install -y build-essential gfortran wget unzip curl equivs ghostscript \
    libcurl4-gnutls-dev m4 git automake flex bison libjpeg-dev libpixman-1-dev \
    vim less \
    libreadline-dev libncursesw5-dev libssl-dev tk-dev \
    libgdbm-dev libc6-dev libbz2-dev libffi-dev \
    cmake libtiff-dev

RUN echo "Downloading GhostScript fonts from ${GSFONT_URL} into /usr/local/share/met" \
 && mkdir -p /usr/local/share/met \
 && curl -SL ${GSFONT_URL} | tar zxC /usr/local/share/met

#
# CVE-2023-45853
#   Install zlib 1.3.1 from source to avoid CVEs in the zlib1g-dev 1.2.13 package
#
RUN echo "Downloading zlib from ${ZLIB_URL}" \
 && wget ${ZLIB_URL} \
 && tar xzf zlib-1.3.1.tar.gz \
 && cd zlib-1.3.1 \
 && ./configure --enable-shared \
 && make -j `nproc` \
 && make install

#
# CVE-2025-6965 and CVE-2025-7458
#   Install sqlite3 from source to avoid critical CVEs
#
RUN echo "Downloading and installing sqlite3 from ${SQLITE3_URL}" \
 && wget ${SQLITE3_URL} \
 && filename=$(basename ${SQLITE3_URL}) \
 && tar xzf ${filename} \
 && (cd ${filename%%.*} && ./configure && make -j $(nproc) && make install) &&\
    echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local.conf && ldconfig \
 && echo "Create dummy packages to prevent reinstallation of packages with CVEs" &&\
    ( \
        echo 'Package: libsqlite3-0'; \
        echo 'Version: 9:9.9.9'; \
        echo 'Architecture: amd64'; \
        echo 'Maintainer: Dummy Pkg'; \
        echo 'Description: Dummy package to satisfy libnss3 dependency with source-built sqlite3'; \
    ) > /tmp/libsqlite3-0.control && \
    equivs-build /tmp/libsqlite3-0.control &&\
    dpkg -i libsqlite3-0_9.9.9_amd64.deb

#
# Set the working directory
#
WORKDIR /met

#
# Install Python from source
#
RUN wget https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz \
 && tar xzf Python-${PYTHON_VER}.tgz \
 && (cd Python-${PYTHON_VER} \
 && ./configure --enable-optimizations --enable-shared --disable-test-modules LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" \
 && make -j `nproc` \
 && make install) \
 && ln -s /usr/local/bin/python3 /usr/local/bin/python \
 && rm -rf Python-${PYTHON_VER}*

#
# Compile the MET libraries
#
ARG MET_COMPILE_SCRIPT_BRANCH=main_v12.0
ARG MET_TAR_FILE_VERSION_NAME=met-base-v3.3
RUN echo "Pulling compilation script from MET branch ${MET_COMPILE_SCRIPT_BRANCH}" \
 && wget https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.${MET_TAR_FILE_VERSION_NAME}.tgz \
 && wget https://raw.githubusercontent.com/dtcenter/MET/${MET_COMPILE_SCRIPT_BRANCH}/internal/scripts/installation/compile_MET_all.sh \
 && wget https://raw.githubusercontent.com/dtcenter/MET/${MET_COMPILE_SCRIPT_BRANCH}/internal/scripts/environment/development.docker \
 && tar -zxf tar_files.${MET_TAR_FILE_VERSION_NAME}.tgz \
 && export SKIP_MET=TRUE \
 && chmod +x compile_MET_all.sh \
 && ./compile_MET_all.sh development.docker

#
# Install required Python packages
#
RUN export CPPFLAGS="-I/usr/local/include" \
 && export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" \
 && python3 -m pip install --upgrade pip \
 && python3 -m pip install --no-binary :all: numpy==1.26.4 \
 && python3 -m pip install --no-binary :all: xarray==2023.1.0 \
 && export HDF5_DIR=/usr/local/ \
 && export NETCDF4_DIR=/usr/local/ \
 && python3 -m pip install netCDF4==1.6.2 \
 && python3 -m pip install --no-binary :all: pyyaml==6.0.1 \
 && python3 -m pip install scipy==1.11.1 \
 && python3 -m pip install setuptools==78.1.1

#
# Run linker configuration
#
RUN ldconfig

#
# Remove packages containing Critical CVEs:
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
 && echo "Remove libxml2 again because it was added again from chrome dependencies" &&\
    apt remove -y libxml2 &&\
    apt clean
