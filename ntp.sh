#!/bin/bash
#############################################################################
# NTP for AsusWRT
#
# This script downloads and compiles all packages needed for adding 
# GPS-backed clock synchronization capability to Asus ARM routers.
#
# Before running this script, you must first compile your router firmware so
# that it generates the AsusWRT libraries.  Do not "make clean" as this will
# remove the libraries needed by this script.
#############################################################################
PATH_CMD="$(readlink -f $0)"

set -e
set -x

#REBUILD_ALL=1
PACKAGE_ROOT="$HOME/asuswrt-merlin-addon/asuswrt"
SRC="$PACKAGE_ROOT/src"
ASUSWRT_MERLIN="$HOME/asuswrt-merlin"
TOP="$ASUSWRT_MERLIN/release/src/router"
SYSROOT="$ASUSWRT_MERLIN/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/brcm-arm/bin:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin
MAKE="make -j`nproc`"

############# ###############################################################
# PPS-TOOLS # ###############################################################
############# ###############################################################

DL="pps-tools-1.0.tar.gz"
URL="https://github.com/redlab-i/pps-tools/archive/v1.0.tar.gz"
mkdir -p $SRC/pps-tools && cd $SRC/pps-tools
FOLDER="${DL%.tar.gz*}"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget -O $DL $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

mkdir -p "$PACKAGE_ROOT/usr/bin"
mkdir -p "$PACKAGE_ROOT/usr/include/sys"

CC="arm-brcm-linux-uclibcgnueabi-gcc" \
CFLAGS="-ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -I$SYSROOT/usr/include" \
LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -L$SYSROOT/usr/lib" \
DESTDIR="$PACKAGE_ROOT" \
make install

TIMEPPS_H="$PACKAGE_ROOT/usr/include/sys/timepps.h"
[ ! -f "$PACKAGE_ROOT/usr/include/timepps.h" ] && [ -f "$TIMEPPS_H" ] && cp -p "$TIMEPPS_H" "$PACKAGE_ROOT/usr/include"

touch __package_installed
fi

####### #####################################################################
# NTP # #####################################################################
####### #####################################################################

DL="ntp-4.2.8p9-win.tar.gz"
URL="http://archive.ntp.org/ntp4/ntp-4.2/$DL"
mkdir -p $SRC/ntp && cd $SRC/ntp
FOLDER="${DL%.tar.gz*}"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

# add support for PPS kernel interface (if not already there)
TIMEPPS_H="${PATH_CMD%/*}/timepps.h"
PACKAGE_ROOT_TIMEPPS_H="$PACKAGE_ROOT/usr/include/timepps.h"
if [ ! -f "$PACKAGE_ROOT_TIMEPPS_H" ] && [ -f "$TIMEPPS_H" ]; then
  PACKAGE_ROOT_INCLUDE="${PACKAGE_ROOT_TIMEPPS_H%/*}"
  mkdir -p "$PACKAGE_ROOT_INCLUDE"
  cp -p "$TIMEPPS_H" "$PACKAGE_ROOT_INCLUDE"
fi

# build NTP (NEMA+PPS)
PKG_CONFIG_PATH="$PACKAGE_ROOT/lib/pkgconfig" \
OPTS="-DOPENSSL -ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -I$PACKAGE_ROOT/include  -I$PACKAGE_ROOT/usr/include" \
CFLAGS="$OPTS" CXXFLAGS="$OPTS" CPPFLAGS="$OPTS" \
LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections  -L$PACKAGE_ROOT/lib" \
ac_cv_header_md5_h=no ac_cv_lib_rt_sched_setscheduler=no ac_cv_header_dns_sd_h=no hw_cv_func_snprintf_c99=yes hw_cv_func_vsnprintf_c99=yes ac_cv_make_ntptime=yes \
./configure \
--host=arm-brcm-linux-uclibcgnueabi \
'--build=' \
--prefix=$PACKAGE_ROOT \
--enable-static \
--enable-shared \
--enable-local-libopts \
--enable-local-libevent \
--enable-accurate-adjtime \
--without-ntpsnmpd \
--without-lineeditlibs \
--disable-linuxcaps \
--with-crypto \
--with-openssl-libdir=$SYSROOT/usr/lib \
--with-openssl-incdir=$SYSROOT/usr/include \
--enable-autokey \
--enable-openssl-random \
--enable-thread-support \
--with-threads \
--with-yielding-select=yes \
--without-rpath \
--disable-silent-rules \
--disable-all-clocks \
--disable-parse-clocks \
--enable-NMEA \
--enable-ATOM \
--enable-LOCAL-CLOCK

$MAKE
make install
touch __package_installed
fi

############# ###############################################################
# SETSERIAL # ###############################################################
############# ###############################################################

DL="setserial-2.17.tar.gz"
URL="https://downloads.sourceforge.net/project/setserial/setserial/2.17/$DL"
mkdir -p $SRC/setserial && cd $SRC/setserial
FOLDER="${DL%.tar.gz*}"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

mkdir -p "$PACKAGE_ROOT/bin"
mkdir -p "$PACKAGE_ROOT/usr/man"

CC="arm-brcm-linux-uclibcgnueabi-gcc" \
STRIP="arm-brcm-linux-uclibcgnueabi-strip" \
CFLAGS="-ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -I$SYSROOT/usr/include" \
LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -L$SYSROOT/usr/lib" \
./configure \
--host=arm-brcm-linux-uclibcgnueabi \
'--build=' \
--prefix=$PACKAGE_ROOT

$MAKE
DESTDIR="$PACKAGE_ROOT" make install
touch __package_installed
fi

############## ##############################################################
# UTIL-LINUX # ##############################################################
############## ##############################################################

DL="util-linux-2.29.2.tar.xz"
URL="https://www.kernel.org/pub/linux/utils/util-linux/v2.29/$DL"
mkdir -p $SRC/util-linux && cd $SRC/util-linux
FOLDER="${DL%.tar.xz*}"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xvJf $DL
cd $FOLDER

pushd .
cd $TOP/ncurses/lib
[ ! -f libtinfo.so.6 ] && ln -sf libncursesw.so.6 libtinfo.so.6
[ ! -f libtinfo.so ] && ln -sf libtinfo.so.6 libtinfo.so
popd

PKG_CONFIG_PATH="$PACKAGE_ROOT/lib/pkgconfig" \
OPTS="-ffunction-sections -fno-data-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -I$SYSROOT/usr/include -lm" \
CFLAGS="$OPTS" CPPFLAGS="$OPTS" \
LDFLAGS="-ffunction-sections -fno-data-sections -Wl,--gc-sections -L$SYSROOT/usr/lib" \
LIBS="-lm -L$SYSROOT/usr/lib" \
./configure \
--host=arm-brcm-linux-uclibcgnueabi \
'--build=' \
--prefix=$PACKAGE_ROOT \
--enable-shared \
--enable-static \
--disable-rpath \
--disable-silent-rules --disable-makeinstall-chown --disable-makeinstall-setuid --with-sysroot=$SYSROOT \
--disable-agetty \
--without-ncurses --without-ncursesw

$MAKE
make install
touch __package_installed
fi
