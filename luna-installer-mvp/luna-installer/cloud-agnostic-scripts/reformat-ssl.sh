#!/bin/bash
cloud=${1?Error: No cloud given.}

#grab json values from infra.json
customer_inputs="../../${cloud}-infra.json"
key_file=$(python3 parse_creds.py $customer_inputs "certKey")
cert_file=$(python3 parse_creds.py $customer_inputs "certificate")

if [[ "$key_file" == "" && "$cert_file" == "" ]];
then 
    echo "The certificate and pem have already been extracted."
    exit
else
    
    #create temp files to hold unformatted json
    echo $key_file >> key_file_new.key
    echo $cert_file >> cert_file_new.pem
    #make a random hex for this variable
    changedkey="$(openssl rand -hex 3).key"
    changedcert="$(openssl rand -hex 3).pem"
    #reformat the files
    awk '{gsub(/~~~/,"\n")}1' key_file_new.key >> ../../$changedkey
    awk '{gsub(/~~~/,"\n")}1' cert_file_new.pem >> ../../$changedcert
    #update json with new reformatted file
    python3 update_json.py ../../${cloud}-infra.json "certKey" ""
    python3 update_json.py ../../${cloud}-infra.json "certificate" ""

    python3 update_json.py ../../${cloud}-infra.json "key-file-name" $changedkey
    python3 update_json.py ../../${cloud}-infra.json "cert-file-name" $changedcert

    #remove temp files created earlier
    rm key_file_new.key
    rm cert_file_new.pem
fi