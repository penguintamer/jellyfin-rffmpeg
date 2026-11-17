# syntax=docker/dockerfile:1

ARG RFFMPEG_REPO=https://github.com/joshuaboniface/rffmpeg.git
# renovate: datasource=git-refs depName=https://github.com/joshuaboniface/rffmpeg branch=master
ARG RFFMPEG_COMMIT=f54ac843c7c8a157562e7ce37aaebbc5cb41354e

FROM scratch AS rffmpeg
ARG RFFMPEG_REPO
ARG RFFMPEG_COMMIT
ADD ${RFFMPEG_REPO}#${RFFMPEG_COMMIT} /

FROM ghcr.io/jellyfin/jellyfin:12.4@sha256:fea863d0cd9ec445985d9c75fc6ed64e38a1d2766cf0c250a33d553f4fc1b771

RUN apt-get update \
 && apt-get install -y --no-install-recommends libnss-wrapper openssh-client python3-click python3-yaml \
 && rm -rf /var/lib/apt/lists/*

COPY --from=rffmpeg /rffmpeg /usr/local/bin/rffmpeg

RUN ln -s rffmpeg /usr/local/bin/ffmpeg \
 && ln -s rffmpeg /usr/local/bin/ffprobe \
 && chmod 755 /usr/local/bin/rffmpeg

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint

ENTRYPOINT ["/usr/local/bin/entrypoint", "/jellyfin/jellyfin"]
