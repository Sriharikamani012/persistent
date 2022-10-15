import json
import sys
import os.path
#!bin/env python


def file_exists(file_path):
    return os.path.isfile(file_path)
    

def read_json_file(file_path):
    #TODO Error handle if the file exists 
    if(file_exists(file_path)):
        with open(file_path) as f:
            credentials = json.load(f)
            return credentials
    else:
        print("Error - JSON file not found.")
        sys.exit(1)

def get_value(file_path, key):
    creds = read_json_file(file_path)
    print(creds[key])

if __name__ == '__main__':
    get_value(sys.argv[1], sys.argv[2])



