#!/usr/bin/env bash

for i in {1..59}; do
    rsync -qa --delete --inplace -T /tmp /vagrant/nginx-metrix/* /etc/nginx/nginx-metrix
    rsync -qa --delete --inplace -T /tmp /vagrant/nginx-conf/* /etc/nginx/nginx-metrix-conf
    sleep 1
done
