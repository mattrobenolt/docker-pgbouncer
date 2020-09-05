FROM alpine:3.12

RUN addgroup -S pgbouncer && adduser -S -G pgbouncer pgbouncer

RUN apk add --no-cache 'su-exec>=0.2'

ENV PGBOUNCER_VERSION 1.14.0
ENV PGBOUNCER_DOWNLOAD_URL http://www.pgbouncer.org/downloads/files/1.14.0/pgbouncer-1.14.0.tar.gz
ENV PGBOUNCER_DOWNLOAD_SHA256 a0c13d10148f557e36ff7ed31793abb7a49e1f8b09aa2d4695d1c28fa101fee7

RUN set -x \
	&& apk add --no-cache --virtual .fetch-deps curl tar \
	&& curl -fSL "$PGBOUNCER_DOWNLOAD_URL" -o pgbouncer.tar.gz \
	&& echo "$PGBOUNCER_DOWNLOAD_SHA256 *pgbouncer.tar.gz" | sha256sum -c - \
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
	&& ./configure \
		--prefix=/usr/local \
		--with-cares \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& install -d /etc/pgbouncer/ \
	&& install -m 644 /usr/src/pgbouncer/etc/pgbouncer.ini /etc/ \
	&& sed -ri "s!^;?(listen_addr)\s*=\s*\S+.*!\1 = 0.0.0.0!" /etc/pgbouncer.ini \
	&& sed -ri "s!^;?(logfile)\s*=\s*\S+.*!!" /etc/pgbouncer.ini \
	&& sed -ri "s!^;?(pidfile)\s*=\s*\S+.*!!" /etc/pgbouncer.ini \
	&& sed -ri "s!^;?(admin_users)\s*=\s*\S+.*!\1 = pgbouncer!" /etc/pgbouncer.ini \
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

COPY docker-entrypoint.sh /usr/local/bin/

EXPOSE 6432/tcp

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["pgbouncer", "/etc/pgbouncer.ini"]
