#!/usr/bin/env bash

for i in {1..59}; do
    rsync -qa --inplace -T /tmp /vagrant/metrix/* /etc/nginx/metrix
    sleep 1
done
