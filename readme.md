# About
Docker image to run Samba as active directory with minimal setup and a web interface to manage users

https://hub.docker.com/r/dddmaster/samba-ad

# Usage
- adjust .env file
- optionally adjust ports to allow active directory ports
- docker run -p 8080:8080 --hostname ad --env-file .env --cap-add SYS_ADMIN dddmaster/samba-ad

  SYS_ADMIN is required for certain samba file privileges. see https://stackoverflow.com/questions/27989751/mount-smb-cifs-share-within-a-docker-container

# Todo
- change to non root user
- catch errors during domain provisioning
- map configuration for dns, admin username etc to environment
- test internal dns
- adjust container logging output to include samba log
- further investigate SYS_ADMIN cap requirement for documentation purpose and optional optimization.

# AD Ports
https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/config-firewall-for-ad-domains-and-trusts

| client | server | service | 
| ------------- |:-------------:| -----:|
| 1024-65535/TCP | 135/TCP | RPC Endpoint Mapper |
| 1024-65535/TCP | 1024-65535/TCP | RPC for LSA, SAM, NetLogon (*)
| 1024-65535/TCP/UDP | 389/TCP/UDP | LDAP
| 1024-65535/TCP | 636/TCP | LDAP SSL
| 1024-65535/TCP | 3268/TCP | LDAP GC
| 1024-65535/TCP | 3269/TCP | LDAP GC SSL
| 53,1024-65535/TCP/UDP | 53/TCP/UDP | DNS
| 1024-65535/TCP/UDP | 88/TCP/UDP | Kerberos
| 1024-65535/TCP | 445/TCP | SMB
| 1024-65535/TCP | 1024-65535/TCP | FRS RPC (*)
