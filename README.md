Model Evaluation Tools Base Image (METbaseimage)
================================================

This repository contains Dockerfiles which define environments for building and testing the Model Evaluation Tools (MET) software package.

Please see the [MET website](https://dtcenter.org/community-code/model-evaluation-tools-met) and the [MET User's Guide](https://met.readthedocs.io/en/latest) for more information.  Support	for the	METplus components, including this repository, is provided through the [METplus Discussions](https://github.com/dtcenter/METplus/discussions) forum.  Users are welcome and encouraged to answer or address each other's questions there!  For more information, please read "[Welcome to the METplus Components Discussions](https://github.com/dtcenter/METplus/discussions/939)".

Version History
===============

v3.5.4
------

* Upgrade Python to 3.14.4

v3.5.3
------

* Force pandas version to <3

v3.5.2
------

* Separate MET and METviewer images
* Use IronBank debian as base repository

v3.5.1
------

* Update pip install commands to remove deprecated options

v3.5.0
------

* Upgrade to Tomcat 10.1.48

v3.4.10
-------

* Fixed bug installing pandas 2
* Upgrade Python to 3.14.4

v3.4.9
------

* Upgrade Python to 3.14.3
* Upgrade Tomcat to 9.0.115

v3.4.8
------

* Force pandas version to <3

v3.4.7
------

* Separate MET and METviewer images
* Use IronBank debian as base repository


v3.4.6
------

* Update pip install commands to remove deprecated options

v3.4.5
------

* Remove private keys found in Python test libs

v3.4.4
------

* Address Critical CVEs that do not appear in internal grype scan - update tomcat to 9.0.109
  * CVE-2025-31651 (tomcat-util)
  * CVE-2025-24813 (tomcat-util)

v3.4.3
------

* Address the rest of Critical CVEs in METbaseimage ([Internal #62](https://github.com/dtcenter/METplus-Internal/issues/62))
   * Create dummy package for libsqlite3-0 to prevent apt from installing it again

v3.4.2
------

* Address most Critical CVEs in METbaseimage ([Internal #62](https://github.com/dtcenter/METplus-Internal/issues/62))
   * Install sqlite version 3.50.3
   * Install ImageMagick version 7.1.2 without XML support
   * Remove packages containing critical CVEs

v3.4.1
------

* Address Critical CVEs in METbaseimage ([Internal #61](https://github.com/dtcenter/METplus-Internal/issues/61))
  * Python 3.12.11
  * zlib 1.3.1
  * nco 5.3.3

v3.4
----

* Python 3.12.0 (#30)

v3.3.6
------

* Update pip install commands to remove deprecated options

v3.3.5
------

* Remove private keys found in Python test libs


v3.3.4
------

* Address 2 High CVEs - update setuptools (python) to 78.1.1
  * CVE-2024-6345 (GHSA-cx63-2mw6-8hw5)
  * CVE-2025-47273 (GHSA-5rjg-fvgr-3xxf)

v3.3.3
------

* Address Critical CVEs that do not appear in internal grype scan - update tomcat to 9.0.109
  * CVE-2025-31651 (tomcat-util)
  * CVE-2025-24813 (tomcat-util)

v3.3.2
------

* Address Critical CVEs in METbaseimage ([Internal #62](https://github.com/dtcenter/METplus-Internal/issues/62))
   * Install sqlite version 3.50.3
   * Install ImageMagick version 7.1.2 without XML support
   * Remove packages containing critical CVEs
   * Create dummy package for libsqlite3-0 to prevent apt from installing it again

v3.3.1
------

* Address Critical CVEs in METbaseimage ([Internal #61](https://github.com/dtcenter/METplus-Internal/issues/61))
  * Python 3.10.18
  * zlib 1.3.1
  * nco 5.3.3

v3.3
----

* Update METbaseimage to use newer versions of ecKit and Atlas libraries (#27)

v3.2
----

* Install SciPy Python package (#20)

UPDATE: 7/3/2024 Manually pushed the dtcenter/met-base-metviewer:v3.2 image to DockerHub to serve as the new base image for METviewer development and testing (#23)

v3.1
----

* Compile the ecKit and Atlas libraries (#13)
* Install the YAML Python package (#15)

v3.0
----

Increasing the major version number from 2 to 3 because of the operating system version change from Debian 10 to 12.

* Completes transition to debian base image using Debian 12 (bookworm)
* Adds Proj library dependency
* Note that upgrading from Debian 10 to 12 requires that the METplus [runtime environements](https://github.com/dtcenter/METplus/tree/develop/internal/scripts/docker_env) also be upgraded to Debian 12

v2.0_debian10
-------------

* Uses debian:10-slim as base image
* Python 3.10.4

v1.1
----

* Update NetCDF libraries to support groups (needed for ioda2nc enhancements)
* Update versions of HDF5 and NetCDF libraries to mirror WCOSS2

v1.0
----

* Initial release
* Uses centos:7 as base image

How to Use Dockerfiles
======================

GitHub actions are triggered for each new tag created in this repository to automatically build images from these Dockerfiles and push them to DockerHub repositories. These images form the basis of additional Dockerfiles in the other METplus component repositories for their compilation and/or testing.

1. `Dockerfile` defines the base compilation environment for MET. Tagged versions are available in the [dtcenter/met-base](https://hub.docker.com/repository/docker/dtcenter/met-base) DockerHub repository. It can be built manually by running:
```
docker build -t dtcenter/met-base:v3.4 -f Dockerfile .
docker push dtcenter/met-base:v3.4
```

2. `Dockerfile.unit_test_env` extends the `dtcenter/met-base` image by adding packages required for running the MET unit tests. Tagged versions are available in the [dtcenter/met-base-unit-test](https://hub.docker.com/repository/docker/dtcenter/met-base-unit-test) DockerHub repository. It can be built manually by running:
```
export MET_BASE_TAG=v3.4
docker build -t dtcenter/met-base-unit-test:v3.4 \
  --build-arg MET_BASE_TAG \
  -f Dockerfile.unit_test_env .
docker push dtcenter/met-base-unit-test:v3.4
```

where:
* `${MET_BASE_TAG}` is the version of [dtcenter/met-base](https://hub.docker.com/repository/docker/dtcenter/met-base) to be used
