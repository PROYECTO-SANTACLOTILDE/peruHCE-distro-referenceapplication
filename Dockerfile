# syntax=docker/dockerfile:1

### Dev Stage 
FROM openmrs/openmrs-core:${TAG_CORE:-2.7.3-dev} AS dev
WORKDIR /openmrs_distro

# Setting credentials for Git Hub Maven Package
ARG GHP_USERNAME
ARG GHP_PASSWORD

# Adding Git Hub Maven Package credentials
COPY credentials/settings.xml.template /root/.m2/settings.xml

ARG MVN_ARGS_SETTINGS="-s /root/.m2/settings.xml -gs /usr/share/maven/ref/settings-docker.xml -U -P distro"
ARG MVN_ARGS="install"

# Copy build files
COPY pom.xml ./
COPY distro ./distro/

# Build the distro, but only deploy from the amd64 build
RUN --mount=type=secret,id=m2settings,target=/usr/share/maven/ref/settings-docker.xml if [[ "$MVN_ARGS" != "deploy" || "$(arch)" = "x86_64" ]]; then mvn $MVN_ARGS_SETTINGS $MVN_ARGS; else mvn $MVN_ARGS_SETTINGS install; fi

RUN cp /openmrs_distro/distro/target/sdk-distro/web/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/

RUN cp /openmrs_distro/distro/target/sdk-distro/web/openmrs-distro.properties /openmrs/distribution/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_modules /openmrs/distribution/openmrs_modules/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_owas /openmrs/distribution/openmrs_owas/
RUN cp -R /openmrs_distro/distro/target/sdk-distro/web/openmrs_config /openmrs/distribution/openmrs_config/

# Clean up after copying needed artifacts
RUN mvn $MVN_ARGS_SETTINGS clean

### Run Stage
# Replace 'nightly' with the exact version of openmrs-core built for production (if available)
FROM openmrs/openmrs-core:${TAG_CORE:-2.7.3}

# Do not copy the war if using the correct openmrs-core image version
COPY --from=dev /openmrs/distribution/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/

COPY --from=dev /openmrs/distribution/openmrs-distro.properties /openmrs/distribution/
COPY --from=dev /openmrs/distribution/openmrs_modules /openmrs/distribution/openmrs_modules
COPY --from=dev /openmrs/distribution/openmrs_owas /openmrs/distribution/openmrs_owas
COPY --from=dev  /openmrs/distribution/openmrs_config /openmrs/distribution/openmrs_config
