#!/bin/sh
#
# Note: This build script assumes it can find the archive for libwebp 
# in the current directory. You can download it from the following URL:
#  http://code.google.com/speed/webp/download.html
#
# The resulting framework will can be found in the current directory 
# with the name WebP.framework
#

SDK=7.0
PLATFORMS="iPhoneSimulator iPhoneOS-V7 iPhoneOS-V7s iPhoneOS-V64"
DEVELOPER=`xcode-select -print-path`
TOPDIR=`pwd`
BUILDDIR="$TOPDIR/tmp"
FINALDIR="$TOPDIR/WebP.framework"
LIBLIST=''
DEVROOT="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain"

rm libwebp-0.4.0.tar.gz
wget https://webp.googlecode.com/files/libwebp-0.4.0.tar.gz

mkdir -p $BUILDDIR
mkdir -p $FINALDIR
mkdir $FINALDIR/Headers/

for PLATFORM in ${PLATFORMS}
do
  if [ "${PLATFORM}" == "iPhoneOS-V7" ]
  then
    SDKPATH="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk/"
    ARCH="armv7"
  elif [ "${PLATFORM}" == "iPhoneOS-V7s" ]
  then
    SDKPATH="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk/"
    ARCH="armv7s"
  elif [ "${PLATFORM}" == "iPhoneOS-V64" ]
  then
    SDKPATH="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk/"
    ARCH="arm64"
  else
    SDKPATH="${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk/"
    ARCH="i386"
  fi

  export CC=${DEVROOT}/usr/bin/cc
  export LD=${DEVROOT}/usr/bin/ld
  export CPP=${DEVROOT}/usr/bin/cpp
  export CXX=${DEVROOT}/usr/bin/g++
  export AR=${DEVROOT}/usr/bin/ar
  export AS=${DEVROOT}/usr/bin/as
  export NM=${DEVROOT}/usr/bin/nm
  export CXXCPP=${DEVROOT}/usr/bin/cpp
  export RANLIB=${DEVROOT}/usr/bin/ranlib

  rm -rf libwebp-0.4.0
  tar xzf libwebp-0.4.0.tar.gz

  if [ "${PLATFORM}" == "iPhoneOS-V64" ]
  then
    # disable neon for 64 bit environment
    patch libwebp-0.4.0/src/dsp/dsp.h disable_64bit_neon
  fi

  cd libwebp-0.4.0

  sh autogen.sh

  ROOTDIR="/tmp/install.$$.${ARCH}"
  rm -rf "${ROOTDIR}"
  mkdir -p "${ROOTDIR}"

  export LDFLAGS="-arch ${ARCH} -miphoneos-version-min=6.1 -pipe -no-cpp-precomp -isysroot ${SDKPATH}"
  export CFLAGS="-arch ${ARCH} -miphoneos-version-min=6.1 -pipe -no-cpp-precomp -isysroot ${SDKPATH}"
  export CXXFLAGS="-arch ${ARCH} -miphoneos-version-min=6.1 -pipe -no-cpp-precomp -isysroot ${SDKPATH}"

  if [ "${PLATFORM}" == "iPhoneOS-v64" ]
  then
    ./configure --host=${ARCH}-apple-darwin --prefix=${ROOTDIR} --disable-shared --enable-static
  else
    ./configure --host=aarch64-apple-darwin --prefix=${ROOTDIR} --disable-shared --enable-static
  fi
  make
  make install

  LIBLIST="${LIBLIST} ${ROOTDIR}/lib/libwebp.a"
  cp -Rp ${ROOTDIR}/include/webp/* $FINALDIR/Headers/

  cd ..
done

${DEVROOT}/usr/bin/lipo -create $LIBLIST -output $FINALDIR/WebP

rm -rf libwebp-0.3.1
rm -rf ${BUILDDIR}
