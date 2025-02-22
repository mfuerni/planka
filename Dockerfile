FROM node:lts AS client-builder

WORKDIR /app

COPY client/package.json client/package-lock.json ./

RUN npm install npm@latest --global \
  && npm install

COPY client .
RUN npm run build

FROM node:lts-alpine

WORKDIR /app

COPY server/.npmrc server/package.json server/package-lock.json ./

ARG ALPINE_VERSION=3.15
ARG VIPS_VERSION=8.12.2

RUN apk -U upgrade \
  && apk add \
  bash giflib glib lcms2 libexif \
  libgsf libjpeg-turbo libpng librsvg libwebp \
  orc pango tiff \
  --repository https://alpine.global.ssl.fastly.net/alpine/v${ALPINE_VERSION}/community/ \
  --repository https://alpine.global.ssl.fastly.net/alpine/v${ALPINE_VERSION}/main/ \
  --no-cache \
  && apk add \
  build-base giflib-dev glib-dev lcms2-dev libexif-dev \
  libgsf-dev libjpeg-turbo-dev libpng-dev librsvg-dev libwebp-dev \
  orc-dev pango-dev tiff-dev \
  --virtual vips-dependencies \
  --repository https://alpine.global.ssl.fastly.net/alpine/v${ALPINE_VERSION}/community/ \
  --repository https://alpine.global.ssl.fastly.net/alpine/v${ALPINE_VERSION}/main/ \
  --no-cache \
  && wget -O- https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz | tar xzC /tmp \
  && cd /tmp/vips-${VIPS_VERSION} \
  && ./configure \
  && make \
  && make install-strip \
  && cd $OLDPWD \
  && rm -rf /tmp/vips-${VIPS_VERSION} \
  && npm install npm@latest --global \
  && npm install --production \
  && apk del vips-dependencies --purge

COPY docker-start.sh start.sh
COPY server .

RUN chmod +x start.sh \
  && cp .env.sample .env

COPY --from=client-builder /app/build public
COPY --from=client-builder /app/build/index.html views

VOLUME /app/public/user-avatars
VOLUME /app/public/project-background-images
VOLUME /app/public/attachments

EXPOSE 1337

CMD ["./start.sh"]
