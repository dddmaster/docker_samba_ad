FROM alpine:edge
ARG DOMAIN
ARG ADMINPASS
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN apk update && \
	apk add chrony samba-dc krb5 git py3-pip build-base gcc python3-dev openldap-dev bash
COPY smb.conf /etc/samba/smb.conf
COPY resolv.conf /etc/resolv.conf
COPY entry.sh /entry.sh
RUN ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf && \
	mkdir -p /var/run/samba && \
	chmod u+x /entry.sh && \
	chmod -R 666 /var/lib/samba/sysvol
RUN cd /root/ && \
	git clone https://github.com/VicentGJ/AD-webmanager.git && \
	cd AD-webmanager && \
	sed -i 's/python-ldap==3.4.0/python-ldap==3.4.3/g' /root/AD-webmanager/requirements.txt
RUN pip install -r /root/AD-webmanager/requirements.txt --break-system-packages
COPY webmanager.conf /root/AD-webmanager/.env
ENTRYPOINT ["/entry.sh"]
