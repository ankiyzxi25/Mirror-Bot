FROM python:3-slim-buster

WORKDIR /usr/src/app
COPY . .

RUN set -ex \
    # setup env
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get -qq -y install software-properties-common \
    && apt-add-repository non-free \
    && apt-get -qq update \
    && apt-get -qq -y install --no-install-recommends \
        # build deps
        autoconf automake g++ gcc git libtool m4 make swig \
        # mega sdk deps
        libc-ares-dev libcrypto++-dev libcurl4-openssl-dev \
        libfreeimage-dev libsodium-dev libsqlite3-dev libssl-dev zlib1g-dev \
        # mirror bot deps
        aria2 curl ffmpeg jq locales p7zip-full p7zip-rar pv python3-lxml \
    && apt-get -qq -y autoremove --purge \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    # setup mega sdk
    && MEGA_SDK_VERSION="3.8.6" \
    && git clone https://github.com/meganz/sdk.git --depth=1 -b v$MEGA_SDK_VERSION ~/sdk \
    && cd ~/sdk \
    && rm -rf .git \
    && ./autogen.sh \
    && ./configure --disable-silent-rules --enable-python --with-sodium --disable-examples \
    && make -j$(nproc --all) \
    && cd bindings/python/ \
    && python3 setup.py bdist_wheel \
    && cd dist/ \
    && pip3 install --no-cache-dir megasdk-$MEGA_SDK_VERSION-*.whl \
    && cd ~/sdk \
    # setup mirror bot
    && cd /usr/src/app \
    && chmod 777 /usr/src/app \
    && pip3 install --no-cache-dir -r requirements.txt \
    && cp netrc /root/.netrc \
    && cp extract pextract /usr/local/bin \
    && chmod +x aria.sh /usr/local/bin/extract /usr/local/bin/pextract \
    # cleanup env
    && apt-get -qq -y purge --autoremove \
        autoconf automake g++ gcc git libtool m4 make software-properties-common swig \
    && apt-get -qq -y clean \
    && rm -rf -- /var/lib/apt/lists/* /var/cache/apt/archives/* /etc/apt/sources.list.d/*

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

CMD ["bash", "start.sh"]
