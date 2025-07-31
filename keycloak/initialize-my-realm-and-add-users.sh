#!/bin/bash

# SPDX-FileCopyrightText: 2025 ICRC
#
# SPDX-License-Identifier: BSD-3-Clause

function wait_for_keycloak() {
  local -r MAX_WAIT=30
  local wait_time
  wait_time=0

  # Waiting for kcadm.sh to succeed
  success="no"
  while [[ "${success}" != "yes" ]]; do
    if [[ ${wait_time} -ge ${MAX_WAIT} ]]; then
      echo "ERROR: The application service did not start within 60 seconds. Aborting."
      exit 1
    else
      sh /opt/keycloak/bin/kcadm.sh config credentials \
          --server http://localhost:${KC_HTTP_PORT}  \
          --realm master --user "${KEYCLOAK_ADMIN}" --password "${KEYCLOAK_ADMIN_PASSWORD}"
        if [[ $? -eq 0 ]]; then
          success="yes"
        else
          echo "INFO: Keycloak admin authentication failed; retry after 2 seconds! Waiting (${wait_time}/${MAX_WAIT}) ..."
          sleep 2
          ((++wait_time))
      fi
    fi
  done
  echo "INFO: Keycloak is ready"
}
sleep 10
echo "Wait for Keycloak"
# Waiting for Keycloak to start before proceeding with the configurations.
wait_for_keycloak

REALM=${REALM:-main}
KC_HTTP_PORT=${KC_HTTP_PORT:-8080}
ANDROID_SDK_CLIENT_ID=${ANDROID_SDK_CLIENT_ID:-openmrs-fhir}
ANDROID_SDK_REDIRECT_URIS=${ANDROID_SDK_REDIRECT_URIS:-org.openmrs.android.fhir.app:/oauth2redirect}
OMRS_CLIENT_ID=${OMRS_CLIENT_ID:-openmrs}
OMRS_REDIRECT_URIS=${OMRS_REDIRECT_URIS:-http://localhost:8080/*}
OMRS_FRONTCHANNEL_LOGOUT_URI=${OMRS_FRONTCHANNEL_LOGOUT_URI:-http://localhost:8080/openmrs/ms/logout}

sh /opt/keycloak/bin/kcadm.sh create realms -s realm="${REALM}" -s enabled=true   -s sslRequired=none
echo "INFO: Created REALM ${REALM}"
sh /opt/keycloak/bin/kcadm.sh create clients -r "${REALM}" -s clientId="${ANDROID_SDK_CLIENT_ID}" \
  -s publicClient=true -s directAccessGrantsEnabled=true \
  -s redirectUris="[\"${ANDROID_SDK_REDIRECT_URIS}\"]" -i
echo "INFO: Created the new ${ANDROID_SDK_CLIENT_ID} client"

sh /opt/keycloak/bin/kcadm.sh create clients -r "${REALM}" -s clientId="${OMRS_CLIENT_ID}" \
  -s publicClient=false -s directAccessGrantsEnabled=false \
  -s secret="${OMRS_OAUTH_CLIENT_SECRET}" \
  -s frontchannelLogout=true \
  -s "attributes.\"frontchannel.logout.url\"=${OMRS_FRONTCHANNEL_LOGOUT_URI}" \
  -s redirectUris="[\"${OMRS_REDIRECT_URIS}\"]" -i
echo "INFO: Created the new ${OMRS_CLIENT_ID}"

while read email; do
  username=$(echo "${email}"|cut -d @ -f 1)
  firstname=$(echo "${username}"|cut -d . -f 1)
  lastname=$(echo "${username}"|cut -d . -f 2)
  sh /opt/keycloak/bin/kcadm.sh create users -r ${REALM} \
    -s username="${username}" \
    -s firstName="${firstname}" \
    -s lastName="${lastname}" \
    -s email="${email}" \
    -s enabled=true \
    -s emailVerified=true \
    -s credentials="[{\"type\":\"password\",\"value\":\"${USERS_DEFAULT_PASSWORD}\"}]"
  echo "Create username ${username} with email ${email}"
done </opt/keycloak/bin/users.csv