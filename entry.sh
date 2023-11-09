#!/bin/bash
#TODO: move away from root directory
#TODO: catch invalid admin password or anything else from domain provisioning

# check domain env variable
if [[ "" == "$DOMAIN" ]]; then
	echo "MISSING DOMAIN ENV"
	exit
fi

arrDOMAIN=(${DOMAIN//./ })

#check if domain includes at least one .
if [[ ${#arrDOMAIN[@]} -lt 2 ]]; then
	echo "INVALID DOMAIN"
	exit
fi

subDOMAIN=${arrDOMAIN[$((${#arrDOMAIN[@]} - 2))]}

#check admin password and use fallback
if [[ "" == "$ADMINPASS" ]]; then
	ADMINPASS=12qw34er!
fi

#create samba db if it doesnt exist
if [[ ! -e  /var/lib/samba/private/secrets.tdb ]]; then
	# build DN string start
	#bla.morebla.bl = DC=bla,DC=morebla,DC=bl
	SEARCH_DN=""
	FIRST=true

	for i in "${arrDOMAIN[@]}"; do
		if [[ ! $FIRST == true ]]; then
			SEARCH_DN="${SEARCH_DN},"
		fi
		FIRST=false
		SEARCH_DN="${SEARCH_DN}DC=$i"
	done
	#build dn string stop

	# fill configs
	sed -i "s/<netlogonpath>/\/var\/lib\/samba\/sysvol\/$DOMAIN\/scripts/g" /etc/samba/smb.conf
	sed -i "s/workgroup = /workgroup = $subDOMAIN/g" /etc/samba/smb.conf
	sed -i "s/realm = /realm = $DOMAIN/g" /etc/samba/smb.conf
	sed -i "s/SECRET_KEY=/SECRET_KEY=$(echo -n $ADMINPASS|md5sum)/g" /root/AD-webmanager/.env
	sed -i "s/LDAP_DOMAIN=/LDAP_DOMAIN=$DOMAIN/g" /root/AD-webmanager/.env
	sed -i "s/SEARCH_DN=/SEARCH_DN=$SEARCH_DN/g" /root/AD-webmanager/.env
	echo "127.0.0.1 	localhost.$subDOMAIN localhost" >> /etc/hosts
	echo "$(hostname -i) 	ad.$DOMAIN ad" >> /etc/hosts

	mkdir -p /var/lib/samba/sysvol/$DOMAIN/scripts

	samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=SAMBA_INTERNAL --realm=$DOMAIN --domain=$subDOMAIN --adminpass=$ADMINPASS
fi

#start samba
/usr/sbin/samba

#start webinterface
cd /root/AD-webmanager
python ADwebmanager.py
