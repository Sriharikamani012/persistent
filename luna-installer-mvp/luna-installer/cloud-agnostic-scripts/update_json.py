import json
import sys
import os.path
import importlib  
parse_json = importlib.import_module("parse_creds")
#!bin/env python

def update_value(file_path, key, storage_account):
    creds = parse_json.read_json_file(file_path)
    creds[key]=storage_account
    print(creds[key])
    out_file = open(file_path,'w')
    out_file.write(json.dumps(creds, indent=1))

    return 0

if __name__ == '__main__':
    update_value(sys.argv[1], sys.argv[2], sys.argv[3])
