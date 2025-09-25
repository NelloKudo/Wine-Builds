FROM registry.gitlab.steamos.cloud/proton/sniper/sdk:3.0.20250210.116596-0 AS main-deps

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/usr/lib/gcc-14/bin:$PATH"

RUN update-alternatives --install /usr/bin/gcc gcc /usr/lib/gcc-14/bin/gcc 90 \
    --slave /usr/bin/g++ g++ /usr/lib/gcc-14/bin/g++ \
    --slave /usr/bin/gcov gcov /usr/lib/gcc-14/bin/gcov

FROM main-deps AS manual-deps

ENV FFMPEG_VERSION="7.1.1" \
    LIBXKBCOMMON_VERSION="1.9.2" \
    GSTREAMER_VERSION="1.22" \
    LLVM_MINGW_VERSION="20250402" \
    XZ_VERSION="5.6.4" \
    LIBUNWIND_VERSION="1.8.1" \
    GCC_MINGW_VERSION="14.2.0-1" \
    LIBGLVND_VERSION="1.7.0" \
    PATH="/usr/local/llvm-mingw/bin:$PATH"

RUN wget -O llvm-mingw-${LLVM_MINGW_VERSION}.tar.xz \
    https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION}/llvm-mingw-${LLVM_MINGW_VERSION}-msvcrt-ubuntu-20.04-x86_64.tar.xz && \
    tar -xf llvm-mingw-${LLVM_MINGW_VERSION}.tar.xz -C /usr/local && \
    rm -rf /usr/local/llvm-mingw && \
    mv /usr/local/llvm-mingw-${LLVM_MINGW_VERSION}-msvcrt-ubuntu-20.04-x86_64 /usr/local/llvm-mingw

WORKDIR /build

RUN wget -O libxkbcommon.tar.gz https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-${LIBXKBCOMMON_VERSION}.tar.gz && \
    tar -xf libxkbcommon.tar.gz && \
    cd libxkbcommon-xkbcommon-${LIBXKBCOMMON_VERSION} && \
    export LIBRARY_PATH="usr/lib:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/i386/lib/i386-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:${LIBRARY_PATH:-}" && \
    export LD_LIBRARY_PATH="usr/lib:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/i386/lib/i386-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:${LD_LIBRARY_PATH:-}" && \
    # 64-bit
    echo "[binaries]\nc = 'gcc'\ncpp = 'g++'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86_64'\ncpu = 'x86_64'\nendian = 'little'" > /opt/build64-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    CFLAGS="-static-libgcc" CXXFLAGS="-static-libgcc -static-libstdc++" LDFLAGS="-static-libgcc -static-libstdc++" meson setup --prefer-static \
        --prefix=/usr/local/x86_64 --libdir=/usr/local/x86_64/lib/x86_64-linux-gnu \
        --native-file /opt/build64-conf.txt --buildtype "release" \
        build_x86_64 -Denable-docs=false -Ddefault_library=static -Denable-tools=false \ 
        -Denable-bash-completion=false -Denable-x11=false -Denable-wayland=false -Denable-xkbregistry=true && \
    meson compile -C build_x86_64 xkbcommon:static_library && \
    meson compile -C build_x86_64 xkbregistry:static_library && \
    meson install -C build_x86_64 --no-rebuild --tags devel && \
    rm -rf build_x86_64 && \
    # 32-bit
    echo "[binaries]\nc = 'gcc'\ncpp = 'g++'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86'\ncpu = 'x86'\nendian = 'little'" > /opt/build32-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/i386-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/i386/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    CFLAGS="-m32 -static-libgcc" CXXFLAGS="-m32 -static-libgcc -static-libstdc++" LDFLAGS="-m32 -static-libgcc -static-libstdc++" meson setup --prefer-static \
        --prefix=/usr/local/i386 --libdir=/usr/local/i386/lib/i386-linux-gnu \
        --native-file /opt/build32-conf.txt --buildtype "release" \
        build_i386 -Denable-docs=false -Ddefault_library=static -Denable-tools=false \ 
        -Denable-bash-completion=false -Denable-x11=false -Denable-wayland=false -Denable-xkbregistry=true && \
    meson compile -C "build_i386" xkbcommon:static_library && \
    meson compile -C "build_i386" xkbregistry:static_library && \
    meson install -C "build_i386" --no-rebuild --tags devel

RUN wget -O gstreamer.tar.gz https://gitlab.freedesktop.org/gstreamer/gstreamer/-/archive/${GSTREAMER_VERSION}/gstreamer-${GSTREAMER_VERSION}.tar.gz && \
    tar -xf gstreamer.tar.gz && \
    cd gstreamer-${GSTREAMER_VERSION} && \
    # 64-bit build
    echo "[binaries]\nc = 'gcc'\ncpp = 'g++'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86_64'\ncpu = 'x86_64'\nendian = 'little'" > /opt/build64-conf.txt && \
    meson setup build_x86_64 --prefix=/usr/local/x86_64 --libdir=/usr/local/x86_64/lib/x86_64-linux-gnu --native-file /opt/build64-conf.txt && \
    ninja -C build_x86_64 && \
    ninja -C build_x86_64 install && \
    rm -rf build_x86_64 && \
    # 32-bit build
    echo "[binaries]\nc = 'gcc'\ncpp = 'g++'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86'\ncpu = 'x86'\nendian = 'little'" > /opt/build32-conf.txt && \
    meson setup build_i386 --prefix=/usr/local/i386 --libdir=/usr/local/i386/lib/i386-linux-gnu --native-file /opt/build32-conf.txt && \
    ninja -C build_i386 && \
    ninja -C build_i386 install && \
    rm -rf build_i386

RUN wget -O ffmpeg.tar.xz https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz && \
    tar -xf ffmpeg.tar.xz && \
    cd ffmpeg-${FFMPEG_VERSION} && \
    # 64-bit build
    CFLAGS="-Os -static-libgcc" \
    LDFLAGS="-Os -static-libgcc" \
    ./configure \
        --prefix=/usr/local \
        --enable-shared \
        --enable-static \
        --disable-doc \
        --disable-programs \
        --disable-encoders \
        --disable-muxers \
        --disable-filters \
        --enable-gpl \
        --enable-version3 \
        --disable-debug \
        --enable-nonfree \
        --disable-hwaccels && \
    make -j$(nproc) && \
    make install && \
    make clean && \
    # 32-bit build
    CFLAGS="-m32 -Os -static-libgcc" \
    LDFLAGS="-m32 -Os -static-libgcc" \
    PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig" \
    ./configure \
        --prefix=/usr/local/i386 \
        --libdir=/usr/local/i386/lib/i386-linux-gnu \
        --enable-shared \
        --enable-static \
        --disable-doc \
        --disable-programs \
        --disable-encoders \
        --disable-muxers \
        --disable-filters \
        --enable-gpl \
        --enable-version3 \
        --disable-debug \
        --enable-nonfree \
        --disable-hwaccels \
        --arch=x86_32 \
        --target-os=linux \
        --cross-prefix= \
        --disable-asm && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf ffmpeg-${FFMPEG_VERSION}

RUN wget -O libglvnd.tar.gz https://github.com/NVIDIA/libglvnd/archive/refs/tags/v${LIBGLVND_VERSION}.tar.gz && \
    tar -xf libglvnd.tar.gz && \
    cd libglvnd-${LIBGLVND_VERSION} && \
    export LIBRARY_PATH="/usr/local/llvm-mingw/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/i386/lib/i386-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:${LIBRARY_PATH:-}" && \
    export LD_LIBRARY_PATH="/usr/local/llvm-mingw/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/i386/lib/i386-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:${LD_LIBRARY_PATH:-}" && \
    # 64-bit
    echo "[binaries]\nc = 'clang'\ncpp = 'clang++'\nld = 'lld'\nar = 'llvm-ar'\nstrip = 'llvm-strip'\npkgconfig = 'pkg-config'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86_64'\ncpu = 'x86_64'\nendian = 'little'" > /opt/build64-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    LDFLAGS="-fuse-ld=lld" meson setup build_x86_64 -Dgles1=false \
        --prefix=/usr/local/x86_64 --libdir=/usr/local/x86_64/lib/x86_64-linux-gnu \
        --native-file /opt/build64-conf.txt --buildtype "release" && \
    ninja -C build_x86_64 && \
    ninja -C build_x86_64 install && \
    rm -rf build_x86_64 && \
    # 32-bit
    echo "[binaries]\nc = ['clang','-m32']\ncpp = ['clang++','-m32']\nld = 'lld'\nar = 'llvm-ar'\nstrip = 'llvm-strip'\npkgconfig = 'pkg-config'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86'\ncpu = 'x86'\nendian = 'little'" > /opt/build32-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/i386-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/i386/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    CFLAGS="-m32" LDFLAGS="-m32 -fuse-ld=lld" meson setup build_i386 -Dheaders=false -Dgles1=false \
        --prefix=/usr/local/i386 --libdir=/usr/local/i386/lib/i386-linux-gnu \
        --native-file /opt/build32-conf.txt --buildtype "release" && \
    ninja -C build_i386 && \
    ninja -C build_i386 install

ENV CC="clang" \
    CXX="clang++" \
    CFLAGS="-Os -fPIC -static -fno-stack-protector -fno-stack-check" \
    CXXFLAGS="-Os -fPIC -static -fno-stack-protector -fno-stack-check" \
    LDFLAGS="-Wl,-O1 -static -fuse-ld=lld -static-libgcc -static-libstdc++" \
    PKG_CONFIG="pkg-config --static"

# xz and libunwind for the ntdll.so to not depend on libgcc and liblzma
RUN wget -O xz.tar.gz https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz && \
    tar -xf xz.tar.gz && \
    cd xz-${XZ_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    ../configure --enable-static --disable-shared --prefix=/usr/local && \
    make -j$(nproc) && \
    make install

RUN wget -O libunwind.tar.gz https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz && \
    tar -xf libunwind.tar.gz && \
    cd libunwind-${LIBUNWIND_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    ../configure --enable-static --disable-shared --prefix=/usr/local \
        --disable-minidebuginfo \
        --disable-documentation \
        --disable-tests && \
    make -j$(nproc) && \
    make install

# thank god this exists
RUN wget -O gcc-mingw.tar.xz \
    https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/releases/download/v${GCC_MINGW_VERSION}/xpack-mingw-w64-gcc-${GCC_MINGW_VERSION}-linux-x64.tar.gz && \
    tar -xf gcc-mingw.tar.xz -C /usr/local && \
    rm -rf /usr/local/gcc-mingw && \
    mv /usr/local/xpack-mingw-w64-gcc-${GCC_MINGW_VERSION} /usr/local/gcc-mingw

RUN apt-get -y update && \
    apt-get -y install \
        gawk libkrb5-dev libkrb5-dev:i386 \
        libgstreamer1.0-dev libgstreamer1.0-dev:i386 \
        libgstreamer-plugins-base1.0-dev libgstreamer-plugins-base1.0-dev:i386 && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /build/* /var/lib/apt/lists/*

FROM manual-deps AS temp-layer

COPY wine_builder.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wine_builder.sh

WORKDIR /wine

