#!/bin/bash
#============================================================================#
#variables
host=$HOSTNAME
#===========================================================================
#Setting users,token configs,stopping autoupdates,stopping auto sleeping and outputting configs that need to be set for TPM bind for luks
echo "=== Do you want to set users (y/n) === "
read users
if [[ $users == 'y' ]]; then
	for user in user1 user2; do
		useradd user1
		echo "=== Set PASSWD  ==="
		passwd $user
	done
else
	echo "=== Users Not Set ==="
fi
#===============================================================================================================================================
#Setting FIPS to legacy to allow firefox to run properly and allow IDM binding 
echo "==== Do you want to set FIPS to Legacy and EMS ====?"
read fips
if [[ $fips == 'y' ]]; then
		echo "=== Setting FIPS:LEGACY & EMS ==="     
		for legacy in FIPS:AD-SUPPORT-LEGACY FIPS:AD-SUPPORT-LEGACY:NO-ENFORCE-EMS; do
			update-crypto-policies --set $legacy
	done	
else
	echo "=== LEGACY NOT SET ==="
fi
#===========================================================================================================
#setting sssd/krb5.conf files
echo "=== Do you want to set SSSD.conf? ==="
read sssd
if [[ $sssd == 'y' ]]; then
	echo "[domain]
<REDACTED>
" > /etc/sssd/sssd.conf
cp /etc/sssd/sssd.conf /etc/sssd/sssd.bak
echo "=== SSSD.CONF SET ==="
else
	echo"=== NOT SET SSSD ==="
fi
#====================================================================================
chmod 600 /etc/sssd/sssd.conf
#====================================================================================
echo "=== Do you want to set KRB5.conf? ==="
read krb
if [[ $krb == 'y' ]]; then
	echo "<REDACTED>" > /etc/krb5.conf
  echo "=== KRB5 SET ==="
  cp /etc/krb5.conf /etc/krb5.bak
 else
	 echo "=== KRB5 NOT SET ==="
  fi
#=========================================================================================================
#connecting to IDM
echo "=== Do you want to connect to IDM? ==="
read i
if [[ $i == 'y' ]]; then  
		echo "### Adding system ##"
		kinit admin
		#ipa-client-install --unattended --domain=.DOMAIN --server="SERVER" --hostname=$host --automount-location=domain --principal=ipa-enroll --password=''
		echo "=== What is the OTP? ==="
		read otp
		for i in $otp; do
		ipa-client-install --domain=.domain --server=server --password "$otp";
	done
else
	echo "=== IPA NOT SET ==="
fi
#=================================================================================================================
#changing perms to allow autofs to start
chmod 600 /etc/sssd/sssd.conf
#===================================================================================================================
#starting autofs
echo "=== Do you want to start autofs? ==="
read auto
if [[ $auto == 'y' ]]; then
	echo "### starting autofs ###"     
	ipa-client-automount --server=server --location=domain
else
	echo " === It did NOT work ==="
fi
#============================================================================================================
#Checking TMP and setting crypttab
#systemd-cryptenroll --tpm2-device=list
#============================================================================================================
# sets correct crypttab settings
#echo "=== setting proper crypttab configs in /etc/crypttab ==="
#sed -i 's/swap/swap rd.luks.options=tpm2-device=auto/g' /etc/default/grub
#sed -i 's/none discard/none tpm2-device=auto,discard/g' /etc/crypttab 
#===============================================================================================================
#coping back config files FIXXXXXX
echo "=== COPY SSSD AND KRB.BAK ==="
cp /etc/krb5.keytab /etc/krb5.keytab.bak
cp /etc/krb5.bak /etc/krb5.conf
cp /etc/sssd/sssd.bak /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd
systemctl enable --now autofs
systemctl restart autofs
ls /home
#========================================================================
#setting changes to the grub
echo "=== Do you want to reconfigure the grub file? (y/n) ==="
read grub
if [[ $grub == 'y' ]]; then 
	echo "=== setting crypttab & Grub configs ==="
	sed -i 's/swap/swap rd.luks.options=tpm2-device=auto/g' /etc/default/grub
	sed -i 's/none discard/none tpm2-device=auto,discard/g' /etc/crypttab
	grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
else
	echo "=== grub was not ran ==="
fi
#========================================================================
#binding tmp keys
echo "=== Do you want to configure the TPM keys? (y/n) ===" 
read keys
if [[ $keys == 'y'  ]]; then
		blkid -t TYPE='crypto_LUKS'
		systemd-cryptenroll --tpm2-device=list
		echo "=== What is the path? ==="
		read path
		for dir in root swap var var_log var_log_audit var_tmp tmp home export_home; do
			systemd-cryptenroll --recovery-key /dev/mapper/$path-$dir
       			systemd-cryptenroll /dev/mapper/$path-$dir --tpm2-device=auto --tpm2-pcrs=5;
		done
else 
	echo "=== TPM NOT DONE ==="
fi
#=====================================================================================================
#Setting dracut
echo "=== Do you want to reconfigure the dracut file? (y/n) ==="
read dra
if [[ $dra == 'y'  ]]; then
	dracut -fv --regenerate-all
	systemctl daemon-reload
else
        echo "=== dracut NOT set ==="
fi
#=================================================================================================================================================================
#installing python3.11
echo "=== Do you want to install python 3.11 (y/n) ==="
read py
if [[ $py == 'y' ]]; then
	echo "=== Installing python NOW ==="
	for i in 3.11 3.11-pip; do 
		dnf install -y python$i; 
	done
else
	echo "=== python was not installed ==="
fi
#==================================================================================================================================================================
#setting token authentication
echo "=== Do you want to set up token authentication? y/n ==="
read toke
if [[ $toke == 'y'  ]]; then
	echo "### changing cac to coolkey ###"
	sed -i 's/certificate/#certificate/g' /etc/sssd/conf.d/certificate.conf
	sed -i 's/cac/'key'/g' /etc/opensc.conf
	kinit <REDACTED>
	bash /<REDACTED>/token.sh
else	
	echo "=== Token was not set ==="
fi
#====================================================================================================================================================================
#final settings
echo "### CLEANUP ###"
if [[ $vm == 'y' ]]; then
	for i in sssd autofs pcscd.service; do
		systemctl restart $i
		echo " === Coping files from [/]home & Setting STIG files. ==="
		#alternatives --install /usr/bin/python python3.11 /usr/bin/python3.11
		sed -i 's/StopIdleSessionSec=300/#StopIdleSessionSec=300/g' /etc/systemd/logind.conf
		#sed -i 's/set -g lock-after-time 900/#set -g lock-after-time 900/g' /etc/tmux.conf
		#tmux source-file /etc/tmux.conf
		cp /<REDACTED>/sudoers /etc/sudoers.d/sudoers
		cp /REDACTED>/blacklist.conf /etc/modprobe.d/
		systemctl mask upower sleep.target suspend.target hibernate.target hybrid-sleep.target 
		echo "retry = 3" >> /etc/security/pwhistory.conf
		#echo "[ -n "$PS1" -a -z "$TMUX" ] && exec tmux" >> /etc/bashrc
		fixfiles onboot
		(authselect select sssd with-pwhistory with-sudo with-faillock without-nullok --force)
		authselect current
     	echo "=== POST-SETUP COMPLETE ==="
        	exit
	done
else
	exit
   done
fi
#======================================================================================================================================================

