# build-conf
In this repository all the neccessary files are stored to build an esrocos environment with autoproj

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
  * A directory "esrocos_workspace" will be created 
  * There you will find an env.sh file which has to be sourced
  * Now you can use the esrocos_* tools to start developing and esrocos project

