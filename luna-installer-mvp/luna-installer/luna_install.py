import json
import sys
import os.path, shlex, subprocess
import shutil
import importlib  
from luna_general import *
#!bin/env python

#Check if the credential files are present 
# Be in the luna-installer-mvp directory 
# python3 luna-installer/luna_install.py aws infra.json
if __name__ == '__main__':
    if(len(sys.argv) == 3): 
        cloud= str(sys.argv[1]).lower()
        file_path=sys.argv[2]

        print(os.getcwd())

        confirm_prerequesites(cloud, file_path, "install")
            
        if (confirm_helm_override(cloud) == 0): 
            #TODO ADD ADDITIONAL CHECK FOR THE CERTS
            infra_status = install_infrastructure(cloud)
            if (infra_status == 1): 
                sys.exit(1)
            else: 
                print("Deploying Luna Application")
                # TODO Error Handle here
                if (taint_windows_nodes(cloud) == 0): 
                    logging_monitoring_install(cloud)
                    deploy_luna(cloud)
    else: 
        print("ERROR - Installation script requires two inputs: the cloud input and the infrastructure file.")
        sys.exit(1)






