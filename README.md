Model Evalulation Tools Base Image (METbaseimage)
=================================================

This repository contains Dockerfiles which define environments for building and testing the Model Evaluation Tools (MET) software package.

Please see the [MET website](https://dtcenter.org/community-code/model-evaluation-tools-met) and the [MET User's Guide](https://met.readthedocs.io/en/latest) for more information.  Support	for the	METplus components, including this repository, is provided through the [METplus Discussions](https://github.com/dtcenter/METplus/discussions) forum.  Users are welcome and encouraged to answer or address each other's questions there!  For more information, please read "[Welcome to the METplus Components Discussions](https://github.com/dtcenter/METplus/discussions/939)".

Version History
===============

v2.1
----

* Completes transition to debian base image
* Adds Proj library dependency

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
docker build -t dtcenter/met-base:v2.0_debian10 -f Dockerfile.debian .
docker push dtcenter/met-base:v2.0_debian10
```

2. `Dockerfile.unit_test_env` extends the `dtcenter/met-base` image by adding packages required for running the MET unit tests. Tagged versions are available in the [dtcenter/met-base-unit-test](https://hub.docker.com/repository/docker/dtcenter/met-base-unit-test) DockerHub repository. It can be built manually by running:
```
export MET_BASE_TAG=v2.0_debian10
docker build -t dtcenter/met-base-unit-test:v2.0_debian10 \
  --build-arg MET_BASE_TAG \
  -f Dockerfile.debian_unit_test_env .
docker push dtcenter/met-base-unit-test:v2.0_debian10
```

where:
* `${MET_BASE_TAG}` is the version of [dtcenter/met-base](https://hub.docker.com/repository/docker/dtcenter/met-base) to be used
