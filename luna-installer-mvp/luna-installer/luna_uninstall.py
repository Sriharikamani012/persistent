import json
import sys
import os.path, shlex, subprocess
from luna_general import *
#!bin/env python

#Check if the credential files are present 
#python3 luna-install.py aws infra.json
if __name__ == '__main__':
    if(len(sys.argv) == 3 ): 
        cloud= str(sys.argv[1]).lower()
        file_path=sys.argv[2]

        print(os.getcwd())
        confirm_prerequesites(cloud, file_path, "uninstall")
        delete_luna(cloud)
        #TODO if getting the kubecontext fails don't attempt to do anything else
        uninstall_infrastructure(cloud)
    else: 
        print("ERROR - Uninstall script requires two inputs: the cloud input and the infrastructure file.")
        sys.exit(1)


