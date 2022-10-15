import json
import sys
import os.path, shlex, subprocess
import shutil
import importlib  
from luna_general import *

#!bin/env python

def upgrade_kubernetes(cloud): 
    try:
        subprocess.run(["./{}-kubeconfig.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        subprocess.run(["./{}-upgrade-k8s.sh".format(cloud,cloud,cloud), "1.17"], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Kubernetes Upgrade Failed.")
        sys.exit(1)



#Check if the credential files are present 
# Be in the luna-installer-mvp directory 
# python3 luna-installer/luna_install.py aws infra.json
if __name__ == '__main__':
    if(len(sys.argv) == 3): 
        cloud= str(sys.argv[1]).lower()
        file_path=sys.argv[2]

        print(os.getcwd())
        confirm_prerequesites(cloud, file_path, "upgrade")
        if (confirm_helm_override(cloud) == 0): 
            print("Passed Prerequesite Checks.")
            upgrade_kubernetes(cloud)
            if (taint_windows_nodes(cloud) == 0):
                upgrade_luna(cloud)
                #Upload Upgrade Logs
                update_logs(cloud)


    else: 
        print("ERROR - Upgrade script requires two inputs: the cloud input and the infrastructure file.")
        sys.exit(1)

    







