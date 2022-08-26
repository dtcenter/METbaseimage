Model Evalulation Tools Base Image (METbaseimage)
=================================================

This repository contains necessary files for the Docker image for the for environment to build the Model Evaluation Tools (MET) package. 

Please see the [MET website](https://dtcenter.org/community-code/model-evaluation-tools-met) and the [MET User's Guide](https://met.readthedocs.io/en/latest) for more information.  Support	for the	METplus	components is provided through the [METplus Discussions](https://github.com/dtcenter/METplus/discussions) forum.  Users are welcome and encouraged to answer or address each other's questions there!  For more information, please read "[Welcome to the METplus Components Discussions](https://github.com/dtcenter/METplus/discussions/939)".

## How to Use Dockerfiles

### Build image with minimum requirements needed to build MET
### NOTE: Replace X.Y with the major and minor release numbers in the command below.

```
docker build -t dtcenter/met-base:minimum_vX.Y -f Dockerfile .
docker push dtcenter/met-base:minimum
```

