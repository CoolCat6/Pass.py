#!/bin/bash

repo='subscription-manager repos --disable=sat*'

for man in repos; do 
	subscription-manager --disable rhel-*-*
	$repo --disable=sat*
#	dnf config-manager --add-repo='repo'
#	dnf config-manager --add-repo='repo'
#	dnf config-manager --add-repo='repo'
	dnf clean all
	dnf update -y;
 done
