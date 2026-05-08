FROM docker.io/library/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Broad set of runtime libs covering Qt5/Qt6, GTK3, multimedia, secrets, etc.
# AppImages typically bundle their own toolkit libs but link against host libc,
# libstdc++, libGL, the xcb stack and a handful of GTK/multimedia bits.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        fontconfig \
        fonts-dejavu-core \
        adwaita-icon-theme \
        hicolor-icon-theme \
        libfontconfig1 \
        libfreetype6 \
        libgl1 \
        libgl1-mesa-dri \
        libegl1 \
        libglu1-mesa \
        libvulkan1 \
        mesa-vulkan-drivers \
        libglib2.0-0t64 \
        libglib2.0-bin \
        libdbus-1-3 \
        libnss3 \
        libnspr4 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        libxcb1 \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-render0 \
        libxcb-shape0 \
        libxcb-shm0 \
        libxcb-sync1 \
        libxcb-util1 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        libxtst6 \
        libxcursor1 \
        libxi6 \
        libgtk-3-0t64 \
        libpango-1.0-0 \
        libcairo2 \
        libatk1.0-0t64 \
        libatk-bridge2.0-0t64 \
        libatspi2.0-0t64 \
        libsecret-1-0 \
        libnotify4 \
        libasound2t64 \
        libpulse0 \
        libgssapi-krb5-2 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# xdg-open shim: forward URL clicks to the host browser via the freedesktop
# OpenURI portal. The host's session DBus socket is bind-mounted at runtime;
# if no portal is running on the host, gdbus errors out and the calling app
# falls back to its existing "no browser" warning -- no regression.
RUN <<'EOF'
cat > /usr/local/bin/xdg-open <<'SHIM'
#!/bin/sh
exec gdbus call --session \
    --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.portal.OpenURI.OpenURI \
    "" "$1" "{}" >/dev/null
SHIM
chmod +x /usr/local/bin/xdg-open
EOF

RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u 1000 ua

USER ua
WORKDIR /home/ua

ENV QT_X11_NO_MITSHM=1 \
    QT_QPA_PLATFORM=xcb

# /opt/app is supplied at runtime as a bind-mount of the extracted AppImage tree.
ENTRYPOINT ["/opt/app/AppRun"]
