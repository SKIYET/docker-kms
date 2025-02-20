# :: Util
  FROM 11notes/util AS util

# :: Build / py-kms
  FROM alpine/git AS build
  ARG APP_VERSION
  RUN set -ex; \
    git clone https://github.com/Py-KMS-Organization/py-kms.git -b next; \
    cd /git/py-kms; \
    git checkout ${APP_VERSION}; \
    cp -R /git/py-kms/docker/docker-py3-kms-minimal/requirements.txt /git/py-kms/py-kms/requirements.txt; \
    cp -R /git/py-kms/docker/docker-py3-kms/requirements.txt /git/py-kms/py-kms/requirements.gui.txt;

# :: Header
  FROM 11notes/alpine:stable

  # :: arguments
    ARG TARGETARCH
    ARG APP_IMAGE
    ARG APP_NAME
    ARG APP_VERSION
    ARG APP_ROOT
    ARG APP_UID
    ARG APP_GID

  # :: environment
    ENV APP_IMAGE=${APP_IMAGE}
    ENV APP_NAME=${APP_NAME}
    ENV APP_VERSION=${APP_VERSION}
    ENV APP_ROOT=${APP_ROOT}

    ENV KMS_LOCALE=1033
    ENV KMS_CLIENTCOUNT=26
    ENV KMS_ACTIVATIONINTERVAL=120
    ENV KMS_RENEWALINTERVAL=259200
    ENV KMS_LOGLEVEL="INFO"

  # :: multi-stage
    COPY --from=util /usr/local/bin/ /usr/local/bin
    COPY --from=build /git/py-kms/py-kms/ /opt/py-kms

# :: Run
  USER root
  RUN eleven printenv;

  # :: install application
    RUN set -ex; \
      apk --no-cache --update add \
        python3; \
      apk --no-cache --update --virtual .build add \
        py3-pip;

    RUN set -ex; \
      mkdir -p ${APP_ROOT}/var; \
      pip3 install --no-cache-dir -r /opt/py-kms/requirements.txt --break-system-packages; \
      pip3 install --no-cache-dir pytz --break-system-packages; \
      apk del --no-network .build;

  # :: copy filesystem changes and set correct permissions
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin; \
      chown -R 1000:1000 \
        ${APP_ROOT} \
        /opt/py-kms;

  # :: support unraid
    RUN set -ex; \
      eleven unraid

# :: Volumes
  VOLUME ["${APP_ROOT}/var"]

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s CMD netstat -an | grep -q 1688 || exit 1

# :: Start
  USER docker