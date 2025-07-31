FROM quay.io/keycloak/keycloak:25.0

USER root

COPY custom-kc.sh /opt/keycloak/bin/custom-kc.sh
COPY initialize-my-realm-and-add-users.sh /opt/keycloak/bin/initialize-my-realm-and-add-users.sh
COPY users.csv /opt/keycloak/bin/users.csv

RUN chmod +x /opt/keycloak/bin/custom-kc.sh
RUN chmod +x /opt/keycloak/bin/initialize-my-realm-and-add-users.sh

USER keycloak

ENTRYPOINT ["/opt/keycloak/bin/custom-kc.sh"]