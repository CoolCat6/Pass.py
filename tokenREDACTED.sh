#!/bin/bash 

# bash script to run instalation script for token auth and sets paramiters for permisions to reduce trouble shooting when setting it

echo "Please Kinit before instalation"

token=sssd_auth_ca_db.pem

cd /etc/sssd/pki/
for lego in /etc/sssd/pki/sssd_auth_ca_db.pem; do
	if [[ -r /etc/sssd/pki/sssd_auth_ca_db.pem ]]; then 
		echo "sssd_auth is installed"
		
	elif ! [[ -r /etc/sssd/pki/sssd_auth_ca_db.pem ]]; then
		cd /Desktop/Files/SAVE/bash/
		/bin/bash /Desktop/Files/SAVE/bash/config-client-smart-card-rhel8.sh $token; 
		echo "					"
		echo "Install Script is Running now"
		echo "					"
	else 
		exit
	fi
echo "### Do you want to copy and set configurations for the SSSD and .pemfile? Y/N? ####"
read question
if [[ $question == "y" ]]; then
	#cd /Desktop/Files/SAVE/bash
	/bin/cp /Desktop/Files/SAVE/bash/sssd_auth_ca_db.pem /etc/sssd/pki/sssd_auth_ca_db.pem;
	echo "			"
	echo ".pem file copied"	
	echo "			"
	chmod -v 640 /etc/sssd/pki/sssd_auth_ca_db.pem
	echo "				"
	echo "Permision to file changed"
	echo "				"
	#cd /Desktop/Files/SAVE/bash/
	echo "					"
	echo "sssd has cleaned & restarted"
	echo "					"
	systemctl daemon-reload
	systemctl daemon-reexec
	fixfiles relabel
	/bin/bash ~/Desktop/Files/SAVE/bash/sssd_cashremove.sh
	systemctl restart pcscd.service
elif
	[[ $question == "n" ]]; then
	echo "Duces!"
else
	exit 

fi

done

# need auth select setup 