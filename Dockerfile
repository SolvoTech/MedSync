FROM alpine:3.19

ARG APK_PATH
ARG APP_VERSION
ARG COMMIT_SHA
ARG BUILD_DATE

LABEL org.opencontainers.image.title="MedSync"
LABEL org.opencontainers.image.description="MedSync Android APK"
LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT_SHA}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

RUN mkdir -p /app
COPY ${APK_PATH} /app/medsync.apk

CMD ["echo", "MedSync APK is available at /app/medsync.apk"]
