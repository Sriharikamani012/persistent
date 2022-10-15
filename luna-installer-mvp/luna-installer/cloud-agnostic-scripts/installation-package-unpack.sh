#!/bin/bash
#Untars file and stores the files in the artifacts directory
openssl enc -d -pbkdf2 -in installation-package.tar.gz | tar xz -C .

cp -r helm-charts/* artifacts/

cp helm-override.yaml artifacts/

rm -r helm-charts