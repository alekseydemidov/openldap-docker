#!/bin/bash

echo "Init environment variables..."

DEBUG_LEVEL=${DEBUG_LEVEL:-256}
#LDAP_TLS_CIPHER_SUITE=${LDAP_TLS_CIPHER_SUITE:-'DEFAULT'}
LDAP_TLS_CIPHER_SUITE=${LDAP_TLS_CIPHER_SUITE:-'HIGH:MEDIUM:-SSLv2:-SSLv3'}
LDAP_TLS=${LDAP_TLS:-false}
LDAP_TLS_ONLY=${LDAP_TLS_ONLY:-false}
LDAP_TLS_CRT_PATH=${LDAP_TLS_CRT_PATH:-'/usr/share/ca-certificates/trust-source'}
LDAP_TLS_CRT_FILENAME=${LDAP_TLS_CRT_FILENAME:-'/certs/tls.crt'}
LDAP_TLS_KEY_FILENAME=${LDAP_TLS_KEY_FILENAME:-'/certs/tls.key'}
LDAP_TLS_DH_PARAM_FILENAME=${LDAP_TLS_DH_PARAM_FILENAME:-'/certs/dhparam.pem'}
LDAP_TLS_CA_CRT_FILENAME=${LDAP_TLS_CA_CRT_FILENAME:-'/certs/ca.crt'}
LDAP_ORGANISATION=${LDAP_ORGANISATION:-'org_name'}
LDAP_BASE_DN=${LDAP_BASE_DN:-'dc=example,dc=com'}
LDAP_DOMAIN=`echo $LDAP_BASE_DN | awk -F ",|=" '{ print $2"."$4 }'`
LDAP_MAX_DB_SIZE=${LDAP_MAX_DB_SIZE:-1073741824}

LDAP_ADMIN_NAME=${LDAP_ADMIN_NAME:-'admin'}
LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD:-'adminsecret'}
LDAP_GROUP_ADMIN=${LDAP_GROUP_ADMIN:-'Admins'}

LDAP_READONLY_USER=${LDAP_READONLY_USER:-false}
LDAP_READONLY_USER_USERNAME=${LDAP_READONLY_USER_USERNAME:-'readuser'}
LDAP_READONLY_USER_PASSWORD=${LDAP_READONLY_USER_PASSWORD:-'readsecret'}



if [ ! -f /etc/openldap/slapd.d/.init ]; then
    cp -rf /init/openldap /etc/
    cp -rf /init/openldap-data /var/lib/openldap/
    cp /etc/openldap/slapd.conf /etc/openldap/slapd.conf.back
    cp -f /init/slapd.conf /etc/openldap/

    echo "Configuration..."
    sed -i -e "s|LDAP_MAX_DB_SIZE|$LDAP_MAX_DB_SIZE|g" /etc/openldap/slapd.conf
    sed -i -e "s|LDAP_BASE_DN|$LDAP_BASE_DN|g" /etc/openldap/slapd.conf
    sed -i -e "s|LDAP_ADMIN_NAME|$LDAP_ADMIN_NAME|g" /etc/openldap/slapd.conf
    sed -i -e "s|LDAP_ADMIN_PASSWORD|$(slappasswd -s $LDAP_ADMIN_PASSWORD)|g" /etc/openldap/slapd.conf

    if [ "${LDAP_READONLY_USER,,}" == "true" ]; then
        sed -i -e "s|LDAP_READONLY_USER_USERNAME|$LDAP_READONLY_USER_USERNAME|g" /etc/openldap/slapd.conf
    else
        sed -i -e "/.*LDAP_READONLY_USER_USERNAME.*/d" /etc/openldap/slapd.conf
    fi

    if [ "${LDAP_GROUP_ADMIN,,}" == "" ]; then
        sed -i -e "/.*LDAP_GROUP_ADMIN.*/d" /etc/openldap/slapd.conf
    else
        sed -i -e "s|LDAP_GROUP_ADMIN|$LDAP_GROUP_ADMIN|g" /etc/openldap/slapd.conf
    fi

    if [ "${LDAP_TLS,,}" == "true" ]; then
        echo "Configuration TLS..."
        sed -i -e '/^TLS.*/d' /etc/openldap/slapd.conf
        echo "" >> /etc/openldap/slapd.conf
        echo "# Certificate/TSL Section" >> /etc/openldap/slapd.conf
        echo "TLSCipherSuite $LDAP_TLS_CIPHER_SUITE" >> /etc/openldap/slapd.conf
        echo "TLSCertificateFile $LDAP_TLS_CRT_FILENAME" >> /etc/openldap/slapd.conf
        echo "TLSCertificateKeyFile $LDAP_TLS_KEY_FILENAME" >> /etc/openldap/slapd.conf
        echo "TLSCACertificateFile $LDAP_TLS_CA_CRT_FILENAME" >> /etc/openldap/slapd.conf
        echo "TLSCACertificatePath $LDAP_TLS_CRT_PATH" >> /etc/openldap/slapd.conf
    fi


    echo 'Test and populate configuration'
    if slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/; then
        touch /etc/openldap/slapd.d/.init
        echo "Succeeded"
    else
        echo "Initialisation DB"
        slapadd -l /dev/null -f /etc/openldap/slapd.conf
        slapindex
        echo 'Test and populate configuration'
        slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/
        touch /etc/openldap/slapd.d/.init
        echo "Succeeded"
    fi
fi

if [ -f /init/init.sh ]; then
    echo "First DB initialisation"
    slapd -4 -F /etc/openldap/slapd.d/ -h "ldap:/// ldaps:///"
    /init/init.sh
    kill -TERM `cat /run/openldap/slapd.pid`
fi

if $LDAP_TLS_ONLY; then
    slapd -d$DEBUG_LEVEL -4 -F /etc/openldap/slapd.d/ -h "ldaps:///"
else
    slapd -d$DEBUG_LEVEL -4 -F /etc/openldap/slapd.d/ -h "ldap:/// ldaps:///"
fi


