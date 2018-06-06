# build-conf
In this repository all the neccessary files are stored to build an esrocos environment with autoproj

##
build status:
[![Build Status](https://esrocosbuild.hb.dfki.de:8443/buildStatus/icon?job=nightly master)](https://esrocosbuild.hb.dfki.de:8443/job/nightly master)

## How to install
1. Download the install_esrocos script
   ```
   wget https://raw.githubusercontent.com/ESROCOS/buildconf/stable/install_esrocos;chmod +x install_esrocos
   ```
2. Execute the install_esrocos script
   ```
   ./install_esrocos
   ```
  * The script will guide you through the installation 
  * A directory "~/esrocos_workspace" will be created 
  * There you will find an env.sh file which has to be sourced
  * Now you can use the esrocos_* tools to start developing and esrocos project
  
## How to customize

ESROCOS is a project distributed over several repositories (of which many can be found within this github organisation). The buildconf manifest constitutes a default layout for your local installation which can be tailored to your projects needs. ESROCOS packages are bundled in package sets which are arranged after their contents.

![Image of ESROCOS packages](images/esrocos_packages.png)
