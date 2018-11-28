FROM alpine:3.8

RUN addgroup -S pgbouncer && adduser -S -G pgbouncer pgbouncer

RUN apk add --no-cache 'su-exec>=0.2'

ENV PGBOUNCER_VERSION 1.9.0
ENV PGBOUNCER_DOWNLOAD_URL https://pgbouncer.github.io/downloads/files/1.9.0/pgbouncer-1.9.0.tar.gz
ENV PGBOUNCER_DOWNLOAD_SHA256 39eca9613398636327e79cbcbd5b41115035bca9ca1bd3725539646468825f04

RUN set -x \
	&& apk add --no-cache --virtual .fetch-deps curl tar \
	&& curl -fSL "$PGBOUNCER_DOWNLOAD_URL" -o pgbouncer.tar.gz \
	&& mkdir -p /usr/src/pgbouncer \
	&& tar -xzf pgbouncer.tar.gz -C /usr/src/pgbouncer --strip-components=1 \
	&& rm pgbouncer.tar.gz \
	&& apk del .fetch-deps \
	&& apk add --no-cache --virtual .build-deps \
		c-ares-dev \
		gcc \
		libc-dev \
		libevent-dev \
		linux-headers \
		make \
		openssl-dev \
	&& cd /usr/src/pgbouncer \
	&& ./configure --prefix=/usr/local --with-libevent=libevent-prefix \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& mv -v /usr/src/pgbouncer/etc/pgbouncer.ini /etc/ \
	&& sed -ri "s!^#?(listen_addr)\s*=\s*\S+.*!\1 = *!" /etc/pgbouncer.ini \
	&& sed -ri "s!^#?(logfile)\s*=\s*\S+.*!!" /etc/pgbouncer.ini \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .pgbouncer-rundeps $runDeps \
	&& apk del .build-deps \
	&& rm -r /usr/src/pgbouncer \
	&& rm -r /usr/local/share/doc/pgbouncer

ENV PGBOUNCER_RUNDIR /var/run/pgbouncer

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["pgbouncer", "/etc/pgbouncer.ini"]
