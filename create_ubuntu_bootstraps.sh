#!/usr/bin/env bash

## A script for creating Ubuntu bootstraps for Wine compilation.
##
## debootstrap and perl are required
## root rights are required
##
## About 5.5 GB of free space is required
## And additional 2.5 GB is required for Wine compilation

if [ "$EUID" != 0 ]; then
	echo "This script requires root rights!"
	exit 1
fi

if ! command -v debootstrap 1>/dev/null || ! command -v perl 1>/dev/null; then
	echo "Please install debootstrap and perl and run the script again"
	exit 1
fi

# Keep in mind that although you can choose any version of Ubuntu/Debian
# here, but this script has only been tested with Ubuntu 20.04 Focal
export CHROOT_DISTRO="focal"
export CHROOT_MIRROR="https://ftp.uni-stuttgart.de/ubuntu/"

# Set your preferred path for storing chroots
# Also don't forget to change the path to the chroots in the build_wine.sh
# script, if you are going to use it
export MAINDIR=/opt/chroots
export CHROOT_X64="${MAINDIR}"/${CHROOT_DISTRO}64_chroot

prepare_chroot () {
	CHROOT_PATH="${CHROOT_X64}"
	
	echo "Unmount chroot directories. Just in case."
	umount -Rl "${CHROOT_PATH}"

	echo "Mount directories for chroot"
	mount --bind "${CHROOT_PATH}" "${CHROOT_PATH}"
	mount -t proc /proc "${CHROOT_PATH}"/proc
	mount --bind /sys "${CHROOT_PATH}"/sys
	mount --make-rslave "${CHROOT_PATH}"/sys
	mount --bind /dev "${CHROOT_PATH}"/dev
	mount --bind /dev/pts "${CHROOT_PATH}"/dev/pts
	mount --bind /dev/shm "${CHROOT_PATH}"/dev/shm
	mount --make-rslave "${CHROOT_PATH}"/dev

	rm -f "${CHROOT_PATH}"/etc/resolv.conf
	cp /etc/resolv.conf "${CHROOT_PATH}"/etc/resolv.conf

	echo "Chrooting into ${CHROOT_PATH}"
	chroot "${CHROOT_PATH}" /usr/bin/env LANG=en_US.UTF-8 TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/sbin" /opt/prepare_chroot.sh

	echo "Unmount chroot directories"
	umount -l "${CHROOT_PATH}"
	umount "${CHROOT_PATH}"/proc
	umount "${CHROOT_PATH}"/sys
	umount "${CHROOT_PATH}"/dev/pts
	umount "${CHROOT_PATH}"/dev/shm
	umount "${CHROOT_PATH}"/dev
}

create_build_scripts () {
 	libpcap_version="1.10.4"
  	libxkbcommon_version="1.6.0"

	cat <<EOF > "${MAINDIR}"/prepare_chroot.sh
#!/bin/bash

apt-get update
apt-get -y install nano
apt-get -y install locales
echo ru_RU.UTF_8 UTF-8 >> /etc/locale.gen
echo en_US.UTF_8 UTF-8 >> /etc/locale.gen
locale-gen
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main universe > /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main universe >> /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-security main universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-security main universe >> /etc/apt/sources.list
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y install software-properties-common
dpkg --add-architecture i386
apt-get update

## Installing Wine dependencies needed to compile...
apt-get -y install wget git libunwind-dev autoconf bison cmake ccache debhelper desktop-file-utils docbook-to-man docbook-utils docbook-xsl flex fontforge gawk gettext libacl1-dev libasound2-dev libcapi20-dev libcups2-dev libdbus-1-dev libgif-dev libglu1-mesa-dev libgphoto2-dev libgsm1-dev libgtk-3-dev libkrb5-dev libxi-dev liblcms2-dev libldap2-dev libmpg123-dev libncurses5-dev libopenal-dev libosmesa6-dev libpcap-dev libpulse-dev libsane-dev libssl-dev libtiff5-dev libudev-dev libv4l-dev libva-dev libxslt1-dev libxt-dev ocl-icd-opencl-dev oss4-dev prelink sharutils unixodbc-dev valgrind schedtool libfreetype6-dev xserver-xorg-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gcc-multilib g++-multilib curl fonttools libsdl2-dev python3-tk libvulkan1 libc6-dev linux-libc-dev libkdb5-* libppl14 libcolord2 libvulkan-dev libgnutls28-dev libpng-dev libkadm5clnt-mit* libkadm5srv-mit* libavcodec-dev libavutil-dev libswresample-dev libavcodec58 libswresample3 libavutil56 libvkd3d-dev libxinerama-dev libxcursor-dev libxrandr-dev libxcomposite-dev mingw-w64 glslang-dev glslang-tools meson wget python3-pefile rustc cargo python3-ldb samba-libs samba-dev libgcrypt20-dev libusb-1.0-0-dev yasm jq
apt-get -y install libunwind-dev:i386 xserver-xorg-dev:i386 libfreetype6-dev:i386 libfontconfig1-dev:i386 libglu1-mesa-dev:i386 libglu1-mesa:i386 libgl1-mesa-dev:i386 libgl1:i386 libosmesa6-dev:i386 libosmesa6:i386 mesa-common-dev:i386 libegl1-mesa-dev:i386 libegl-dev:i386 libgl-dev:i386 libglx-dev:i386 libglx0:i386 libllvm12:i386 libgles-dev:i386 libglvnd-dev:i386 libgles2-mesa-dev:i386 libvulkan-dev:i386 libvulkan1:i386 libpulse-dev:i386 libopenal-dev:i386 libncurses-dev:i386 libvkd3d-dev:i386 libgnutls28-dev:i386 libtiff-dev:i386 libldap-dev:i386 libcapi20-dev:i386 libpcap-dev:i386 libxml2-dev:i386 libmpg123-dev:i386 libgphoto2-dev:i386 libsane-dev:i386 libcupsimage2-dev:i386 libgsm1-dev:i386 libxslt1-dev:i386 libv4l-dev:i386 libudev-dev:i386 libxi-dev:i386 liblcms2-dev:i386 libibus-1.0-dev:i386 libsdl2-dev:i386 ocl-icd-opencl-dev:i386 libxinerama-dev:i386 libxcursor-dev:i386 libxrandr-dev:i386 libxcomposite-dev:i386 libavcodec58:i386 libswresample3:i386 libavutil56:i386 valgrind:i386 libgcrypt20-dev:i386 samba-libs:i386 python3-ldb:i386 python3-talloc:i386 python3:i386 samba-dev:i386 libusb-1.0-0-dev:i386 libgstreamer1.0-dev:i386 libgstreamer-plugins-base1.0-dev:i386
apt-get -y install wayland-protocols libwayland-egl-backend-dev libwayland-egl-backend-dev:i386 libwayland-dev  
apt-get -y install python3-pip libxcb-xkb-dev libxcb-xkb-dev:i386
pip3 install meson
pip3 install ninja
export PATH="/usr/local/bin:\${PATH}"
wget -O /usr/include/linux/ntsync.h https://raw.githubusercontent.com/zen-kernel/zen-kernel/refs/heads/6.13/main/include/uapi/linux/ntsync.h
wget -O /usr/include/linux/userfaultfd.h https://raw.githubusercontent.com/zen-kernel/zen-kernel/refs/heads/6.13/main/include/uapi/linux/userfaultfd.h

# Compiling libxkbcommon from source (not in Ubuntu 20.04 repos)...
wget -O libxkbcommon.tar.xz https://xkbcommon.org/download/libxkbcommon-${libxkbcommon_version}.tar.xz
tar -xf libxkbcommon.tar.xz
cd libxkbcommon-${libxkbcommon_version}
rm -rf build
rm -rf build_i386

# 64bit libxkbcommon...
meson setup build -Denable-docs=false
ninja -C build
ninja -C build install
rm -rf build

# 32bit libxkbcommon...
echo "[binaries]
c = '/usr/bin/gcc'
cpp = '/usr/bin/g++'
ar = 'ar'
strip = 'strip'
pkgconfig = 'pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'x86'
cpu = 'i386'
endian = 'little'
" | tee /opt/build32-conf.txt

export PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig"
export LD_LIBRARY_PATH="/usr/lib/i386-linux-gnu"
CFLAGS="-m32" LDFLAGS="-m32" meson setup build_i386 -Denable-docs=false --prefix=/usr/local/i386 --libdir=lib/i386-linux-gnu \
--native-file /opt/build32-conf.txt 
ninja -C build_i386
ninja -C build_i386 install
rm /opt/build32-conf.txt 
cd ..
rm libxkbcommon.tar.xz

# Cleaning...
apt-get -y clean
apt-get -y autoclean
EOF

	chmod +x "${MAINDIR}"/prepare_chroot.sh
	mv "${MAINDIR}"/prepare_chroot.sh "${CHROOT_X64}"/opt
}

mkdir -p "${MAINDIR}"

debootstrap --arch amd64 $CHROOT_DISTRO "${CHROOT_X64}" $CHROOT_MIRROR

create_build_scripts
prepare_chroot
rm "${CHROOT_PATH}"/opt/prepare_chroot.sh

echo "Done"
