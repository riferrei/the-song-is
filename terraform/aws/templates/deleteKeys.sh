#!/bin/bash

ssh ec2-user@${bastion_server} -i cert.pem 'bash -s' < doDeleteKeys.sh
