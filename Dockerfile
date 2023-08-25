ARG DEBIAN_VERSION=10
FROM debian:${DEBIAN_VERSION}-slim
MAINTAINER George McCabe <mccabe@ucar.edu>

#
# Define the compilers.
#
ENV CC  /usr/bin/gcc
ENV CXX /usr/bin/g++
ENV FC  /usr/bin/gfortran
ENV F77 /usr/bin/gfortran

ENV PYTHON_VER 3.10.4

ENV GSFONT_URL     https://dtcenter.ucar.edu/dfiles/code/METplus/MET/docker_data/ghostscript-fonts-std-8.11.tar.gz

#
# Setup the environment for interactive bash shell.
# Set soft limit to unlimited to prevent GRIB2 seg faults
#
RUN echo export MET_BASE=/usr/local/share/met >> /root/.bashrc \
 && echo export MET_FONT_DIR=/usr/local/share/met/fonts >> /root/.bashrc \
 && echo export RSCRIPTS_BASE=/usr/local/share/met/Rscripts >> /root/.bashrc \
 && echo ulimit -S -s unlimited >> /root/.bashrc

ENV MET_FONT_DIR /usr/local/share/met/fonts

# Install required system tools
RUN apt update && apt -y upgrade \
  && apt install -y build-essential cmake gfortran wget unzip curl imagemagick \
  libcurl4-gnutls-dev m4 git automake flex bison libjpeg-dev libpixman-1-dev \
  emacs less \
  libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev \
  libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev

#
# Install Python
# https://linuxhint.com/install-python-debian-10/
#
RUN wget https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz \
    && tar xzf Python-${PYTHON_VER}.tgz \
    && cd Python-${PYTHON_VER} \
    && ./configure --enable-optimizations --enable-shared LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" \
    && make -j `nproc` \
    && make install \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install numpy xarray netCDF4

RUN echo "Downloading GhostScript fonts from ${GSFONT_URL} into /usr/local/share/met" \
 && mkdir -p /usr/local/share/met \
 && curl -SL ${GSFONT_URL} | tar zxC /usr/local/share/met

# Fix rules for ghostscript files in convert
# See: https://en.linuxportal.info/tutorials/troubleshooting/how-to-fix-errors-from-imagemagick-imagick-conversion-system-security-policy
#
RUN sed -i 's/policy domain="coder" rights="none" pattern="PS/policy domain="coder" rights="read | write" pattern="PS/g' /etc/ImageMagick-6/policy.xml \
    && sed -i 's/policy domain="coder" rights="none" pattern="EPS"/policy domain="coder" rights="read | write" pattern="EPS"/g' /etc/ImageMagick-6/policy.xml \
    && sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read | write" pattern="PDF"/g' /etc/ImageMagick-6/policy.xml \
    && sed -i 's/policy domain="coder" rights="none" pattern="XPS"/policy domain="coder" rights="read | write" pattern="XPS"/g' /etc/ImageMagick-6/policy.xml

#
# Set the working directory.
#
WORKDIR /met

RUN wget https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz \
    && wget https://raw.githubusercontent.com/dtcenter/MET/feature_2669_proj/internal/scripts/installation/compile_MET_all.sh \
    && wget https://raw.githubusercontent.com/dtcenter/MET/feature_2669_proj/internal/scripts/environment/development.docker \
    && tar -zxf tar_files.tgz \
    && export SKIP_MET=yes \
    && chmod +x compile_MET_all.sh \
    && ./compile_MET_all.sh development.docker
