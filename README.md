# openldap-docker
Openldap Docker image based on alpine distr ( with TLS support ) 

This is very light and easy docker image to build OpenLDAP server. This's base on alpine distributive and has TLS support.

## Building:  
docker build --tag openldap .  
docker run --name openldap -e LDAP_ADMIN_NAME='megaadmin' -e LDAP_ADMIN_PASSWORD='megasecret' netflyer/openldap

## Persistance volume:  
To save data in separate storege you can mount following points:  
/etc/openldap - configuration  
/var/lib/openldap - databases

## Environment variables:  
VARIABLE = default (if not set)  
DEBUG_LEVEL=256  
LDAP_TLS=false (set to true if TLS needed)  
LDAP_TLS_CIPHER_SUITE='HIGH:MEDIUM:-SSLv2:-SSLv3'  
LDAP_TLS_ONLY=false (service will listen only 636 port for ldaps connection)  
LDAP_TLS_CRT_FILENAME='/certs/tls.crt'  
LDAP_TLS_KEY_FILENAME='/certs/tls.key'  
LDAP_TLS_CA_CRT_FILENAME='/certs/ca.crt'  
*Please pay attention, this image does not have TLS certificate by default, you must care about certs files yourself*
LDAP_ORGANISATION='org_name'  
LDAP_BASE_DN='dc=example,dc=com'  
LDAP_MAX_DB_SIZE=1073741824  

LDAP_ADMIN_NAME='admin'  **/DN for login: cn=admin,ou=People,dc=example,dc=com/**  
LDAP_ADMIN_PASSWORD='adminsecret'  
LDAP_GROUP_ADMIN='Admins'   
*The member of this group will have possibility to manage groups and people, if you don't need, just set LDAP_GROUP_ADMIN='false'*

LDAP_READONLY_USER=false  
LDAP_READONLY_USER_USERNAME='readuser'  
LDAP_READONLY_USER_PASSWORD='readsecret'  

## Default outgoing LDAP schema will be:
LDAP_BASE_DN  
ou=Groups  
ou=People (with cn=admin and cn=ROuser if set up)  
ou=pwpolicies

Hyperlink to [dockerhub images](https://hub.docker.com/r/netflyer/openldap)

## Updating:
*V1.2*   
Add ppolicy module   
There's defined 2 policies: builtin - for Manager and/or Reader users   
default - for any another users   
*V1.1*   
Added modules: memberof and refinit   
The most convenient way to use classes:   
groupOfName - for memberof   
and organizationRole - for refinit   

