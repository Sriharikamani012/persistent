# GCP Certificate Installation
This document outlines the installation of the certificate for Luna.

## What files the script accesses
- Access to the generated gcp-infra.json
- Access to the parse-creds.py file

#Script Needs
- This script needs the custom-dns value pulled from gcp-infra.json to be formatted as follows. (EX. = luna.gcp.lunapp.info)
- Default override file provided should have the luna.local string appended in the domain and hosts fields.

# Script Steps
#### (TODO - update code to pass proper values for .crt and .key)
1. Grabs values from the gcp-infra.json file above and puts them in local variables
2. Creates a secret based on the .crt and .key files provided
3. Helm installs a nginx-ingress load balancer
4. Replace default information with customer specific information in the override file

#Run Script
```bash   
    - cd gcp/gcp-scripts
    - ./gcp-cert-install
```

#Check ingress IP
```bash   
    - kubectl get ingress
    OR 
    - kubectl get services -o wide -w nginx-ingress-ingress-nginx-controller
```
-Customer should then update their DNS Zone with this IP

###TODO - Document how to setup your own Domain and DNS Zone if not already setup prior
