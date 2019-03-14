#!/bin/bash

ssh ec2-user@54.81.224.140 -i cert.pem 'bash -s' < doDeleteKeys.sh
