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
	echo "initializing new domain"
	# build DN string start
	#bla.morebla.bl = DC=bla,DC=morebla,DC=bl
	SEARCH_DN=""
	FIRST=true

	# @todo: add overwrite via optional env variable
	DC_IP=(hostname -i | cut -d' ' -f)

	# @TDO: check how to change the hostname and overwrite via an optional env variable 
	DC_HOSTNAME=(hostname)

	for i in "${arrDOMAIN[@]}"; do
		if [[ ! $FIRST == true ]]; then
			SEARCH_DN="${SEARCH_DN},"
		fi
		FIRST=false
		SEARCH_DN="${SEARCH_DN}DC=$i"
	done
	#build dn string stop

	echo "SEARCH_DN: ${SEARCH_DN}"
	echo "DOMAIN: ${DOMAIN}"
	echo "subDOMAIN: ${subDOMAIN}"

	# fill configs
	echo "filling configs"
	sed -i -r "s/<netlogonpath>/\/var\/lib\/samba\/sysvol\/$DOMAIN\/scripts/g" /etc/samba/smb.conf
	
	sed -r "s/workgroup \=.*$/workgroup = $subDOMAIN/g" /etc/samba/smb.conf
	sed -i -r "s/workgroup \=.*$/workgroup = $subDOMAIN/g" /etc/samba/smb.conf
	
	sed -i -r "s/realm \=.*$/realm = $DOMAIN/g" /etc/samba/smb.conf
	sed -i -r "s/SECRET_KEY\=.*$/SECRET_KEY=$(echo -n $ADMINPASS|md5sum)/g" /root/AD-webmanager/.env
	sed -i -r "s/LDAP_DOMAIN\=.*$/LDAP_DOMAIN=$DOMAIN/g" /root/AD-webmanager/.env
	sed -i -r "s/SEARCH_DN\=.*$/SEARCH_DN=$SEARCH_DN/g" /root/AD-webmanager/.env


	# @todo: refactor to use array
	HOSTS_ENTRY_1 = "127.0.0.1	localhost.$subDOMAIN localhost"
	HOSTS_ENTRY_2 = "${DC_IP}	${DC_HOSTNAME}.${DOMAIN} ${DC_HOSTNAME}"

	#temporary storing in a variable is neccesary to keep control signs such as tab
	TMP_CHECK=$(cat /etc/hosts | grep "${HOSTS_ENTRY_1}")
	
	if [[ -z "${TMP_CHECK}" ]]; then
		echo "${HOSTS_ENTRY_1}" >> /etc/hosts
		echo "create entry 1 in hosts"
	fi

	TMP_CHECK=$(cat /etc/hosts | grep "${HOSTS_ENTRY_2}")
		
	if [[ -z "${TMP_CHECK}" ]]; then
		echo "${HOSTS_ENTRY_2}" >> /etc/hosts
		echo "create entry 2 in hosts"
	fi


	
	if [[ -z "$(cat /etc/hosts | grep \"${HOSTS_ENTRY_1}\")" ]]; then
		echo "${HOSTS_ENTRY_1}" >> /etc/hosts
	fi
	
	echo "${DC_IP} ${DC_HOSTNAME}.${DOMAIN} ${DC_HOSTNAME}" >> /etc/hosts

	mkdir -p /var/lib/samba/sysvol/$DOMAIN/scripts

	samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=SAMBA_INTERNAL --realm=$DOMAIN --domain=$subDOMAIN --adminpass=$ADMINPASS
fi

#start samba
/usr/sbin/samba

#start webinterface
cd /root/AD-webmanager
python ADwebmanager.py
