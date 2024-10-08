ARG DEBIAN_VERSION=12
FROM debian:${DEBIAN_VERSION}-slim
MAINTAINER George McCabe <mccabe@ucar.edu>

#
# Define the compilers
#
ENV CC  /usr/bin/gcc
ENV CXX /usr/bin/g++
ENV FC  /usr/bin/gfortran
ENV F77 /usr/bin/gfortran

ENV PYTHON_VER 3.10.4

ENV GSFONT_URL https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/ghostscript-fonts-std-8.11.tar.gz

#
# Set up the environment for interactive bash shell
# Set soft limit to unlimited to prevent GRIB2 seg faults
#
RUN echo export MET_BASE=/usr/local/share/met >> /root/.bashrc \
 && echo export MET_FONT_DIR=/usr/local/share/met/fonts >> /root/.bashrc \
 && echo export RSCRIPTS_BASE=/usr/local/share/met/Rscripts >> /root/.bashrc \
 && echo ulimit -S -s unlimited >> /root/.bashrc

ENV MET_FONT_DIR /usr/local/share/met/fonts

#
# Install required system tools
#
RUN apt update && apt -y upgrade \
 && apt install -y build-essential gfortran wget unzip curl imagemagick \
    libcurl4-gnutls-dev m4 git automake flex bison libjpeg-dev libpixman-1-dev \
    emacs vim less \
    libreadline-dev libncursesw5-dev libssl-dev tk-dev \
    libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev \
    cmake libtiff-dev sqlite3 libsqlite3-dev

RUN echo "Downloading GhostScript fonts from ${GSFONT_URL} into /usr/local/share/met" \
 && mkdir -p /usr/local/share/met \
 && curl -SL ${GSFONT_URL} | tar zxC /usr/local/share/met

#
# Fix rules for ghostscript files in convert
# See: https://en.linuxportal.info/tutorials/troubleshooting/how-to-fix-errors-from-imagemagick-imagick-conversion-system-security-policy
#
RUN sed -i 's/policy domain="coder" rights="none" pattern="PS/policy domain="coder" rights="read | write" pattern="PS/g' /etc/ImageMagick-6/policy.xml \
 && sed -i 's/policy domain="coder" rights="none" pattern="EPS"/policy domain="coder" rights="read | write" pattern="EPS"/g' /etc/ImageMagick-6/policy.xml \
 && sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read | write" pattern="PDF"/g' /etc/ImageMagick-6/policy.xml \
 && sed -i 's/policy domain="coder" rights="none" pattern="XPS"/policy domain="coder" rights="read | write" pattern="XPS"/g' /etc/ImageMagick-6/policy.xml

#
# Set the working directory
#
WORKDIR /met

#
# Install Python from source
#
RUN wget https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz \
 && tar xzf Python-${PYTHON_VER}.tgz \
 && cd Python-${PYTHON_VER} \
 && ./configure --enable-optimizations --enable-shared LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" \
 && make -j `nproc` \
 && make install \
 && ln -s /usr/local/bin/python3 /usr/local/bin/python

#
# Compile the MET libraries
#
ARG MET_COMPILE_SCRIPT_BRANCH=develop
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
RUN BLDOPTS="--global-option=build_ext --global-option=\"-R/usr/local/lib\" --global-option=\"-L/usr/local/lib\"" \
 && python3 -m pip install --upgrade pip \
 && python3 -m pip install ${BLDOPTS} numpy==1.24.2 \
 && python3 -m pip install ${BLDOPTS} xarray==2023.1.0 \
 && export HDF5_DIR=/usr/local/ \
 && export NETCDF4_DIR=/usr/local/ \
 && python3 -m pip install ${BLDOPTS} netCDF4==1.6.2 \
 && python3 -m pip install ${BLDOPTS} pyyaml==6.0.1 \
 && python3 -m pip install scipy==1.11.1

#
# Run linker configuration
#
RUN ldconfig

