FROM alpine
LABEL MAINTAINER="Alexey Demidov <ademidov.info@gmail.com>"
RUN apk update && \
    apk add bash openldap-back-mdb openldap openldap-clients \
    openldap-overlay-ppolicy openldap-overlay-memberof openldap-overlay-refint && \
    rm -rf /var/cache/apk/* ; \
    mkdir /run/openldap/ /etc/openldap/slapd.d /init && \
    cp /var/lib/openldap/openldap-data/DB_CONFIG.example /var/lib/openldap/openldap-data/DB_CONFIG; \
    cp -rf /etc/openldap /init && \
    cp -rf /var/lib/openldap/openldap-data /init


COPY slapd.conf /init/
COPY init.sh /init/
COPY entrypoint.sh /
RUN chmod +x /init/init.sh /entrypoint.sh

EXPOSE 389 636
#VOLUME [ "/etc/openldap", "/var/lib/openldap" ]
ENTRYPOINT ["/entrypoint.sh"] 

