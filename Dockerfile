FROM alpine:3.19

ARG APK_PATH
ARG APP_VERSION
ARG COMMIT_SHA
ARG BUILD_DATE

LABEL org.opencontainers.image.title="MEDISNA"
LABEL org.opencontainers.image.description="MEDISNA Android APK"
LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT_SHA}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

RUN mkdir -p /app
COPY ${APK_PATH} /app/medsync.apk

CMD ["echo", "MEDISNA APK is available at /app/medsync.apk"]
