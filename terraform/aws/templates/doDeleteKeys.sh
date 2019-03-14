#!/bin/bash

redis-cli -h ${redis_host} -p ${redis_port} FLUSHALL
