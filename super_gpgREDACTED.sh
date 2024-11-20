#!/bin/bash
for i in <REDACTED> /etc/yum.repos.d/<REDACTED>; do 
        echo "gpgcheck=1" >> $i;
done	
#################################################
for i in daemon-reload daemon-reexec; do 
	sed -i 's/set superusers="root"/set superusers="user"/' /etc/grub.d/0_users
	grubby --update-kernel=ALL
	grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
	systemctl $i
	cat /etc/grub.d/01_users | grep user
	cat /etc/yum.repos.d/<REDACTED>
	cat /boot/efi/EFI/redhat/grub.cfg | grep user
done
