#!/bin/bash

LDAP_BASE_DN=${LDAP_BASE_DN:-'dc=example,dc=com'}
LDAP_ORGANISATION=${LDAP_ORGANISATION:-'org_name'}
LDAP_DOMAIN=`echo $LDAP_BASE_DN | awk -F ",|=" '{ print $2"."$4 }'`

LDAP_ADMIN_NAME=${LDAP_ADMIN_NAME:-'manager'}
LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD:-'adminsecret'}
LDAP_GROUP_ADMIN=${LDAP_GROUP_ADMIN:-'Admins'}
LDAP_READONLY_USER=${LDAP_READONLY_USER:-false}
LDAP_READONLY_USER_USERNAME=${LDAP_READONLY_USER_USERNAME:-'readuser'}
LDAP_READONLY_USER_PASSWORD=${LDAP_READONLY_USER_PASSWORD:-'readsecret'}
LDAP_READONLY_USER_PASSWORD_SSHA=$(slappasswd -s $LDAP_READONLY_USER_PASSWORD)


if ldapsearch -h localhost -b "$LDAP_BASE_DN" -D "cn=$LDAP_ADMIN_NAME,$LDAP_BASE_DN" -w "$LDAP_ADMIN_PASSWORD" '(objectclass=*)' | grep -E "dn: *$LDAP_BASE_DN" > /dev/null ; then
    echo "DB already ready"
else
echo "Create initial entry"
cat <<EOF> /init/base.ldif
# $LDAP_DOMAIN
dn: $LDAP_BASE_DN
dc: `echo $LDAP_BASE_DN | awk -F ",|=" '{ print $2 }'`
o: $LDAP_ORGANISATION
objectClass: dcObject
objectClass: organization

# Manager, $LDAP_DOMAIN
dn: cn=$LDAP_ADMIN_NAME,$LDAP_BASE_DN
cn: $LDAP_ADMIN_NAME
description: LDAP administrator
objectClass: organizationalRole
objectClass: top
roleOccupant: $LDAP_BASE_DN

# People, $LDAP_DOMAIN
dn: ou=People,$LDAP_BASE_DN
ou: People
objectClass: top
objectClass: organizationalUnit

# Groups, $LDAP_DOMAIN
dn: ou=Group,$LDAP_BASE_DN
ou: Group
objectClass: top
objectClass: organizationalUnit

# Password Policies, $LDAP_DOMAIN
dn: ou=pwpolicies,$LDAP_BASE_DN
ou: pwpolicies
objectClass: top
objectClass: organizationalUnit

# add default policy to DIT
dn: cn=default,ou=pwpolicies,$LDAP_BASE_DN
objectClass: applicationProcess
objectClass: pwdPolicy
cn: default
#pwdAttribute: 2.5.4.35
pwdAttribute: userPassword
pwdMaxAge: 0
pwdExpireWarning: 3600
pwdInHistory: 0
pwdCheckQuality: 0
pwdMaxFailure: 15
pwdLockout: FALSE
pwdLockoutDuration: 3600
#pwdGraceAuthNLimit: 0
#pwdFailureCountInterval: 0
pwdMustChange: FALSE
pwdMinLength: 6
pwdAllowUserChange: TRUE
pwdSafeModify: FALSE
EOF

if [ "${LDAP_GROUP_ADMIN,,}" != "false" ]; then
cat <<EOF>> /init/base.ldif

# $LDAP_GROUP_ADMIN, $LDAP_DOMAIN
dn: cn=$LDAP_GROUP_ADMIN,ou=Group,$LDAP_BASE_DN
cn: $LDAP_GROUP_ADMIN
objectClass: top
objectClass: posixGroup
gidNumber: 1
EOF
fi

if [ "${LDAP_READONLY_USER,,}" = "true" ]; then
cat <<EOF>> /init/base.ldif

# $LDAP_READONLY_USER_USERNAME, $LDAP_DOMAIN
dn: cn=$LDAP_READONLY_USER_USERNAME,ou=People,$LDAP_BASE_DN
cn: $LDAP_READONLY_USER_USERNAME
objectClass: posixAccount
objectClass: top
description: LDAP RO user
objectClass: organizationalRole
userPassword: $LDAP_READONLY_USER_PASSWORD_SSHA
uid: $LDAP_READONLY_USER_USERNAME
uidNumber: 2
gidNumber: 2
homeDirectory: /sbin/nologin
EOF
fi

ldapadd -h localhost -D "cn=$LDAP_ADMIN_NAME,$LDAP_BASE_DN" -w "$LDAP_ADMIN_PASSWORD" -f /init/base.ldif
rm /init/base.ldif 
fi

rm -rf /init/
