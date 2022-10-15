import json
import sys
import stat
import os.path, shlex, subprocess
from os import path
import shutil


#!bin/env python3

##############################################################################################################
# General JSON Functions
##############################################################################################################
def file_exists(file_path):
    return os.path.isfile(file_path)

def read_json_file(file_path):
    #TODO Error handle if the file exists 
    if(file_exists(file_path)):
        with open(file_path) as f:
            credentials = json.load(f)
            return credentials
    else:
        print("Error - JSON {} not found.".format(file_path))
        sys.exit(1)

def get_value(file_path, key):
    creds = read_json_file(file_path)
    if key in creds: 
        print(creds[key])
    else: 
        #If the key doesn't exist return ""
        print("")

def retain_frontend_notation(cloud): 
    # This function converts the JSON inputs from the Backend structure to the UI naming conventions
    # The directory luna-installer/cloud-configs contains both the frontend and infra JSON input requirements
    # Add new inputs to the config JSON's for more robust error handling
    user_inputs = read_json_file("{}-infra.json".format(cloud))  
    config_file= "luna-installer/cloud-configs/{}-frontend.json".format(cloud)
    config_map = read_json_file(config_file)
    config_map_vals = list(config_map.values())
    config_map_keys = list(config_map.keys())
        
    for i in config_map_vals:
        if i in user_inputs:
            user_inputs[config_map_keys[config_map_vals.index(i)]] = user_inputs.pop(i)

    if "certificate" in user_inputs: 
        user_inputs.pop("certificate")
    if "certKey" in user_inputs: 
        user_inputs.pop("certKey")

    out_file = open("{}-frontend.json".format(cloud),'w')
    out_file.write(json.dumps(user_inputs, indent=1))
    out_file.close()
    return user_inputs


##############################################################################################################
# Infrastructure Deployment Functions
##############################################################################################################
def cloud_provider_auth(cloud): 
    #The file paths will always be the same 
    #The presence of the credentials has already been completed 
    #Start by calling the authentication scripts in the various cloud providers
    try:
        subprocess.run(["./{}-auth.sh".format(cloud,cloud,cloud)], stdout=True, stderr=True, check=True, cwd="{}/{}-scripts/".format(cloud,cloud))
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("Error - Authorizing. Please Resubmit your credentials and try again. Contact Thermo Fisher Administrator.")
        sys.exit(1)
    return 0

def call_cloud_uninstall(cloud): 
    #The file paths will always be the same 
    #The presence of the credentials has already been completed 
    #Start by calling the authentication scripts in the various cloud providers
    # This function invokes all of the uninstall scripts across all of the clouds
    # It will Destroy the Object Storage, Destroy the Kubernetes Cluster, Destroy Anthos into the Cluster, Provide credentials for the user to authenticate in GCP
    # Destroy the RDS Database and upload installation logs into the cloud
    try:
        print("Uninstalling Database")
        subprocess.run(["./{}-destroy-database.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        print("Removing Anthos Link")
        subprocess.run(["./{}-unattach-anthos.sh".format(cloud,cloud,cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        print("Uninstalling Kubernetes Cluster")
        subprocess.run(["./{}-destroy-k8s-cluster.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        print("Uninstalling Object Storage")
        subprocess.run(["./{}-destroy-object-storage.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))

    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Uninstall Failed. Please Contact your Thermo Fisher Representative")
        return 1
    return 0


def chmod_all_scripts(cloud): 
    # chmod_all_scripts is a function which ensures that all of the installation scripts have the appropriate permissions
    # to execute on the ubuntu VM
    try:
        scripts = ["auth.sh", "create-object-storage.sh", "create-k8s-cluster.sh", "attach-anthos.sh", "create-database.sh", "kubeconfig.sh", "clean-up.sh", "create-secret.sh", "destroy-database.sh", "destroy-k8s-cluster.sh", "destroy-object-storage.sh", "init-backends.sh", "upgrade-k8s.sh", "unattach-anthos.sh"]
        # Cloud Specific Scripts
        for i in scripts:
            st = os.stat("./{}/{}-scripts/{}-{}".format(cloud,cloud,cloud, i))
            os.chmod("./{}/{}-scripts/{}-{}".format(cloud,cloud,cloud, i), st.st_mode | stat.S_IEXEC)
        st = os.stat("./{}/{}-scripts/{}".format(cloud,cloud, "rbac-auth.sh"))
        os.chmod("./{}/{}-scripts/{}".format(cloud,cloud, "rbac-auth.sh"), st.st_mode | stat.S_IEXEC)
        
        # Cloud Agnostic Scripts
        scripts = ["luna-helm-apply.sh",  "reformat-ssl.sh",  "install-load-balancer.sh",  "luna-helm-delete.sh",  "uninstall-load-balancer.sh"]
        for i in scripts:
            st = os.stat("./luna-installer/cloud-agnostic-scripts/{}".format(i))
            os.chmod("./luna-installer/cloud-agnostic-scripts/{}".format(i), st.st_mode | stat.S_IEXEC)
    
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to Authorize Bash Scripts to Execute. Restart installation completely.")
        return 1
    return 0 


def call_cloud_installation(cloud): 
    # This function invokes all of the installation scripts across all of the clouds
    # It will Deploy the Object Storage, Create the Kubernetes Cluster, Deploy Anthos into the Cluster, Provide credentials for the user to authenticate in GCP
    # Deploy the RDS Database and upload installation logs into the cloud
    
    try:
        print("Installing Object Storage")
        result = subprocess.run(["./{}-create-object-storage.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        print("Installing Kubernetes Cluster")
        subprocess.run(["./{}-create-k8s-cluster.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        print("Attaching Anthos")
        subprocess.run(["./{}-attach-anthos.sh".format(cloud,cloud,cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        subprocess.run(["./rbac-auth.sh".format(cloud, cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        print("Installing Database")
        subprocess.run(["./{}-create-database.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        print("Uploading Logs to Object Storage")
        subprocess.run(["./{}-clean-up.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))

    except subprocess.CalledProcessError as e:
        #TODO Add write to file here
        print(e.output)
        print("ERROR - Installation Failed. Beginning attempt to recover")
        try:
            subprocess.run(["./{}-clean-up.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="./{}/{}-scripts/".format(cloud,cloud))
        except subprocess.CalledProcessError as e:
            print("Failed to upload logs.")
        return 1
    return 0


def install_infrastructure(cloud): 
    # This function is coordinates the installation of all of the Infrastructure
    
    result = call_cloud_installation(cloud)
    if(result == 1): 
        print("ERROR - Failed to install the infrastructure. Please contact a Thermo Fisher Agent for assistance.")
        return 1
    else: 
        print("Successfully installed the infrastructure.")
        return 0 

def uninstall_infrastructure(cloud): 
    # This function is coordinates the uninstallation of all of the Infrastructure
    print("Permanently uninstalling the infrastructure.")
    result = call_cloud_uninstall(cloud)
    if(result == 1):
        print("ERROR - Failed to uninstall the infrastructure. Please contact a Thermo Fisher Agent to Help manually uninstall.")
        return 1
    else: 
        print("Successfully uninstalled the infrastructure.")
        return 0 


##############################################################################################################
# Application Deployment Functions
##############################################################################################################
def get_helm_chart_paths():

    os.chdir('artifacts') 
    cwd = os.getcwd() 
    
    text_files = [f for f in os.listdir(cwd) if f.endswith('.tgz')]
    text_files2 = [f for f in os.listdir(cwd) if f.endswith('.tar.gz')]
    for i in range(len(text_files2)): 
        text_files.append(text_files2[i])

    os.chdir('../') 
    cwd = os.getcwd()
    print(cwd)
    return text_files

def get_helm_chart_names(chart_paths): 
    chart_names_dict = {}

    for j in chart_paths:
        #Removing File extension 
        j_update = j.replace('.tgz', '').replace('.tar.gz', '')
        #Removing the version number
        res = ''.join([i for i in j_update if not i.isdigit() and i != "."])
        #Stripping the last character if it is a dash
        res = res.rstrip('-')
        chart_names_dict[j] = res

    #Returning the dictionary
    return (chart_names_dict)

def get_list_helm_val_files(chart_names_dict): 
    values_files=""
    os.chdir('artifacts') 
    #Name: values
    vals_options = ["general-values.yaml", "general-values.yml", "{}-values.yaml".format(chart_names_dict), "{}-values.yml".format(chart_names_dict), "helm-override.yaml" , "helm-override.yml"]

    for i in range(len(vals_options)): 
        if path.exists(vals_options[i]): 
            values_files+= " -f {}".format(vals_options[i])
    os.chdir('../') 
    return values_files
    
def generate_kubeconfig(cloud): 
    try:
        subprocess.run(["chmod",  "+x", "{}/{}-scripts/{}-kubeconfig.sh".format(cloud,cloud,cloud)], stdout=True, stderr=True, check=True)
        subprocess.run(["./{}-kubeconfig.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="{}/{}-scripts/".format(cloud,cloud))
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to generate Kubeconfig. Contact Thermo Fisher Administrator if it was expected that a cluster was active.")
        return 1
    return 0 

def deploy_luna(cloud): 
    # This function will install the helm charts if they don't exist and upgrade them if they do exist
    try:
        if (generate_kubeconfig(cloud) == 0): 
            install_load_balancer(cloud)
            helm_chart_dict = get_helm_chart_names(get_helm_chart_paths())
            subprocess.run(["chmod",  "+x", "luna-installer/cloud-agnostic-scripts/luna-helm-apply.sh"], stdout=True, stderr=True, check=True)
            
            for x in helm_chart_dict:
                helm_values = get_list_helm_val_files(helm_chart_dict[x])
                print("Deploying {} Application ".format(x))
                namespace=str(helm_chart_dict[x]).partition("-")
                subprocess.run(["./../luna-installer/cloud-agnostic-scripts/luna-helm-apply.sh", x, helm_chart_dict[x], namespace[0], helm_values], stdout=True, stderr=True, check=True, cwd="artifacts")

    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to Deploy Luna Applications. Contact Thermo Fisher Administrator.")
        sys.exit(1)
    return 0 

def upgrade_luna(cloud): 
    # This function will upgrade the helm charts if there are any updates or changes
    try:
        if (generate_kubeconfig(cloud) == 0): 
            install_load_balancer(cloud)
            helm_chart_dict = get_helm_chart_names(get_helm_chart_paths())
            subprocess.run(["chmod",  "+x", "luna-installer/cloud-agnostic-scripts/luna-helm-apply.sh"], stdout=True, stderr=True, check=True)
            
            for x in helm_chart_dict:
                helm_values = get_list_helm_val_files(helm_chart_dict[x])
                print("Deploying {} Application ".format(x))
                namespace=str(helm_chart_dict[x]).partition("-")
                subprocess.run(["./../luna-installer/cloud-agnostic-scripts/luna-helm-apply.sh", x, helm_chart_dict[x], namespace[0], helm_values], stdout=True, stderr=True, check=True, cwd="artifacts")
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to upgrade Luna Applications. Contact Thermo Fisher Administrator.")
        sys.exit(1)
    return 0 


def delete_luna(cloud): 
    # This function invokes the script to uninstall the helm charts
    try:
        if (generate_kubeconfig(cloud) == 0): 
            logging_monitoring_uninstall(cloud)

            subprocess.run(["chmod",  "+x", "./luna-installer/cloud-agnostic-scripts/uninstall-load-balancer.sh"], stdout=True, stderr=True, check=True)
            subprocess.run(["chmod",  "+x", "./luna-installer/cloud-agnostic-scripts/luna-helm-delete.sh"], stdout=True, stderr=True, check=True)
            subprocess.run(["./uninstall-load-balancer.sh", str(cloud), "lb"], stdout=True, stderr=True, check=True, cwd="luna-installer/cloud-agnostic-scripts/")
            
            subprocess.run(["./../luna-installer/cloud-agnostic-scripts/luna-helm-delete.sh"], stdout=True, stderr=True, check=True, cwd="artifacts")

    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to uninstall Luna. Contact Thermo Fisher Administrator.")
        sys.exit(1)
    return 0 


def update_logs(cloud):
    # Upload Upgrade Logs to object storage
    try:
        print(os.getcwd())

        subprocess.run(["chmod",  "+x", "{}/{}-scripts/{}-update-logs.sh".format(cloud,cloud,cloud)], stdout=True, stderr=True, check=True)
        subprocess.run(["./{}-update-logs.sh".format(cloud)], stdout=True, stderr=True, check=True, cwd="{}/{}-scripts/".format(cloud,cloud))
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to log upgrade. Contact Thermo Fisher Administrator.")
        sys.exit(1)
    return 0 

def logging_monitoring_install(cloud):
    if(cloud != "gcp"):
        try:
            subprocess.run(["chmod",  "+x", "luna-installer/cloud-agnostic-scripts/logging-monitoring-install.sh"], stdout=True, stderr=True, check=True)
            subprocess.run(["./logging-monitoring-install.sh", "k8s", str(cloud)], stdout=True, stderr=True, check=True, cwd="luna-installer/cloud-agnostic-scripts/")
        except subprocess.CalledProcessError as e:
            print(e.output)
            print("ERROR - Failed to deploy logging and monitoring. Contact Thermo Fisher Administrator.")
            sys.exit(1)
        return 0
    else:
        print("Skipping logging and monitoring for GCP.(Redundant)")
        return 0 

def logging_monitoring_uninstall(cloud):
    if(cloud != "gcp"):
        try:
            subprocess.run(["chmod",  "+x", "luna-installer/cloud-agnostic-scripts/logging-monitoring-uninstall.sh"], stdout=True, stderr=True, check=True)
            subprocess.run(["./logging-monitoring-uninstall.sh", str(cloud)], stdout=True, stderr=True, check=True, cwd="luna-installer/cloud-agnostic-scripts/")
        except subprocess.CalledProcessError as e:
            print(e.output)
            print("ERROR - Failed to uninstall logging and monitoring. Contact Thermo Fisher Administrator.")
            sys.exit(1)
        return 0 
    else:
        print("Skipping logging and monitoring for GCP.(Redundant)")
        return 0

def install_load_balancer(cloud):
    try:
        subprocess.run(["chmod",  "+x", "./luna-installer/cloud-agnostic-scripts/install-load-balancer.sh"], stdout=True, stderr=True, check=True)
        subprocess.run(["./install-load-balancer.sh", str(cloud), "lb"], stdout=True, stderr=True, check=True, cwd="luna-installer/cloud-agnostic-scripts/")
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to Load Balancer. Contact Thermo Fisher Administrator.")
        sys.exit(1)
    return 0 

def taint_windows_nodes(cloud):
    #This is a temporary function and will be removed once the helm charts are updated to node select
    try:
        generate_kubeconfig(cloud)
        subprocess.run(["chmod",  "+x", "./luna-installer/cloud-agnostic-scripts/taint-windows-nodes.sh"], stdout=True, stderr=True, check=True)
        subprocess.run(["./taint-windows-nodes.sh"], stdout=True, stderr=True, check=True, cwd="luna-installer/cloud-agnostic-scripts/")
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed taint the windows nodes. Contact Thermo Fisher Administrator.")
        return 1
    return 0 



##############################################################################################################
# Confirm Prerequesites Functions
##############################################################################################################
def reformat_certificates(cloud): 
    # This function removes the certificates from the input JSON, so the input will NEVER get uploaded to the object storage
    try:
        subprocess.run(["./reformat-ssl.sh", cloud], stdout=True, stderr=True, check=True, cwd="luna-installer/cloud-agnostic-scripts/")     
    except subprocess.CalledProcessError as e:
        print(e.output)
        print("ERROR - Failed to reformat certificates. Contact Thermo Fisher Administrator.")
        sys.exit(1)
    return 0 

def move_valid_inputs(cloud):
    # This function copies the cloud's input json files into the appropriate directories for each of the terraform installments
    shutil.copy("./artifacts/ingress-values-template.yaml", "./artifacts/ingress-values.yaml")
    shutil.copy("{}-infra.json".format(cloud), './{}/{}-object-storage/inputs/dev/{}-infra.json'.format(cloud,cloud,cloud))
    shutil.copy("{}-infra.json".format(cloud), './{}/{}-k8s-cluster/inputs/dev/{}-infra.json'.format(cloud,cloud,cloud))
    shutil.copy("{}-infra.json".format(cloud), './{}/{}-database/inputs/dev/{}-infra.json'.format(cloud,cloud,cloud))

def transpose_input_json(cloud, file_path):
    # This function converts the JSON inputs from the UI structure to the variable names needed for the IaC Scripts
    # The directory luna-installer/cloud-configs contains both the frontend and infra JSON input requirements
    # Add new inputs to those JSON's for more robust error handling
    user_inputs = read_json_file(file_path)
    
    #This function ensures the upload to S3 will be consistant with the frontend notation that the UI requires
    retain_frontend_notation(cloud)
    
    config_file= "luna-installer/cloud-configs/{}-frontend.json".format(cloud)
    config_map = read_json_file(config_file)
    
    for i in config_map:
        if i in user_inputs:
            user_inputs[config_map[i]] = user_inputs.pop(i)

    if "customer-name" in user_inputs: 
        user_inputs["customer-name"] = user_inputs["customer-name"].lower()
        print(user_inputs["customer-name"])

    out_file = open("{}-infra.json".format(cloud),'w')
    out_file.write(json.dumps(user_inputs, indent=1))
    out_file.close()
    return user_inputs

def terraform_required_input_validator(cloud, file_path, journey):
    # If the Input is Optional it should NOT be included in the cloud configs json. 
    # This validation confirms the presence of required inputs and their required types.
    # The directory luna-installer/cloud-configs contains both the frontend and infra JSON input requirements
    # Add new inputs to those JSON's for more robust error handling
    user_inputs = transpose_input_json(cloud, file_path)
    
    config_file= "luna-installer/cloud-configs/{}-{}.json".format(cloud,journey)
    config_map = read_json_file(config_file)
    
    for i in config_map:
        if i in user_inputs:
            if(type(config_map[i]) == type(user_inputs[i])):
                print("Valid - {} key exists in dict".format(i))
            else:
                print("ERROR - Failed user input validation. Type Error in {} field, please have customer resubmit form.".format(i))
                sys.exit(1)
        else:
            print("No {} key does not exists in dict".format(i))
            print("ERROR - Failed user input validation. Please have customer resubmit form.")
            sys.exit(1)
    
    if "gcp_project_id" in user_inputs and cloud == "gcp": 
        #Confirming that the GCP project equals the gcp project provided.
        creds_project = read_json_file("gcp-creds.json") 
        if (str(creds_project["project_id"]) != user_inputs["gcp_project_id"] ): 
            print("GCP Project Credentials do not match the provided Project ID. Confirm inputs and restart installation process.")
            print("ERROR - Failed user input validation. Please have customer resubmit form.")
            return 1
    return 0

def confirm_credentials_presence(cloud):
    print("Checking presence of Cloud Credentials.")
    if(file_exists("{}-creds.json".format(cloud))):
        if(file_exists("gcp-creds.json")):
            return 0
        else: 
            print("ERROR - Valid credentials not provided. Please re-confirm the submission process for GCP's credentials.")
            return 1
    else:
        print("ERROR - Valid credentials not provided. Please re-confirm the submission process for {}'s credentials.".format(cloud))
        return 1

def confirm_helm_override(cloud):
    if(file_exists("helm-override.yaml")):
        print("Helm Override File is present.")
        #TODO Validate Helm Values Files using linter
        # Future Enhancement password lock the installation-package.tar.gz
        if(file_exists("installation-package.tar.gz")): 
            try:
                subprocess.run(["pwd"], stdout=True, stderr=True, check=True)
                subprocess.run(["chmod",  "+x", "luna-installer/cloud-agnostic-scripts/installation-package-unpack.sh"], stdout=True, stderr=True, check=True)
                subprocess.run(["./luna-installer/cloud-agnostic-scripts/installation-package-unpack.sh"], stdout=True, stderr=True, check=True)
                
                helm_charts_list = get_helm_chart_paths()
                #Confirm that there are helm charts present 
                if (len(helm_charts_list) > 0):
                    helm_chart_dict = get_helm_chart_names(helm_charts_list)
                    for x in helm_chart_dict:
                        helm_values = get_list_helm_val_files(helm_chart_dict[x])
                        if(len(helm_values) == 0): 
                            print("ERROR - Thermo Fisher Installation Package did not have appropriate values files. Please contact Thermo Fisher Customer Service.")
                            return 1
                        helm_values = helm_values.replace(' -f', '\n -')
                        print("Installer will deploy {} with the following values files: {}".format(x, helm_values))
                else: 
                    print("ERROR - Thermo Fisher Installation Package did not contain any Helm Charts. Please contact Thermo Fisher Customer Service.")
                    return 1

            except subprocess.CalledProcessError as e:
                print(e.output)
                print("ERROR - Failed to Unzip Thermo Fisher Installation Package. Please contact Thermo Fisher Customer Service.")
                sys.exit(1)
        return 0
    else:
        print("ERROR - Please re-confirm the submission process for the Helm Override File. If this error persists, contact your Thermo Fisher Support Agent.")
        sys.exit(1)

def validate_cloud(cloud):
    if(cloud not in ["aws", "azure", "gcp"]):
        print("ERROR - Invalid input.  Accepted Clouds: aws, azure, or gcp.")
        sys.exit(1)
    else:
        return 0 

def confirm_prerequesites(cloud, file_path, journey):
    if (journey == "install" or journey == "uninstall" or journey == "upgrade"): 
        if (validate_cloud(cloud) == 0 and  confirm_credentials_presence(cloud) == 0 and terraform_required_input_validator(cloud, file_path, journey) == 0): 
            chmod_all_scripts(cloud)
            #Authorize the clouds
            if(cloud_provider_auth(cloud) == 0):
                print("Authorization Clouds - Successfuly Authorized.")
                if(reformat_certificates(cloud) == 0): 
                    move_valid_inputs(cloud) 
                    return 0 
            else: 
                print("Authorization not successful. Please have the user resubmit their credentials")      
        else:
            print("ERROR - Unable to meet Scripts prerequesites. Please restart and try submitting again.")
            sys.exit(1)
    else: 
        print("ERROR - Invalid Journey Input. The three journeys are install, uninstall, or upgrade.")
        sys.exit(1)



#TODO Add function to validate the certificates
#TODO Encrypt file in byte64
