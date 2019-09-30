#!/bin/sh

#  Based on https://github.com/SBKarr/stappler-deps

###########################################################################
#   Download libidn
#
VERSION="1.35"
SDKVERSION=10.0

rm -rf src
mkdir src
cd src

curl -LO ftp://ftp.gnu.org/gnu/libidn/libidn-$VERSION.tar.gz
tar -xzf libidn-$VERSION.tar.gz
rm libidn-$VERSION.tar.gz
mv libidn-$VERSION libidn

cd -

###########################################################################
#   Build settings
#
CFLAGS="-Os"
ORIGPATH=$PATH
LIBNAME=libidn
ROOT=`pwd`

XCODE_BIN_PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
export PATH=$XCODE_BIN_PATH:$PATH

SDK_INCLUDE_SIM="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include"
SDK_INCLUDE_OS="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include"

SYSROOT_SIM="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
SYSROOT_OS="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"

Compile () {
    mkdir -p $LIBNAME
    cd $LIBNAME

    export IPHONEOS_DEPLOYMENT_TARGET="$2"
    HOST_VALUE=$1-apple-darwin
    if [ "$1" == "arm64" ] || [ "$1" == "armv7" ]; then
    HOST_VALUE=arm-apple-darwin
    fi

    ../src/$LIBNAME/configure \
	    CC=$XCODE_BIN_PATH/clang \
	    LD=$XCODE_BIN_PATH/ld \
	    CPP="$XCODE_BIN_PATH/clang -E" \
	    CFLAGS="$CFLAGS -arch $1 -isysroot $4  -miphoneos-version-min=$2" \
	    LDFLAGS="-arch $1 -isysroot $4 -miphoneos-version-min=$2 -L`pwd`/../$1/lib" \
	    CPPFLAGS="-arch $1 -I`pwd`/../$1/include -isysroot $4" \
	    --host=$HOST_VALUE \
	    --with-sysroot="$4" \
	    --prefix=`pwd` \
	    --includedir=`pwd`/../$1/include \
	    --libdir=`pwd`/../$1/lib \
	    --enable-static \
	    --disable-shared \
	    --with-pic=yes

    make
    make install

    cd -
    rm -rf $LIBNAME
}

###########################################################################
#   Compile for given architecture
#
Compile x86_64 $SDKVERSION $SDK_INCLUDE_SIM $SYSROOT_SIM
Compile arm64 $SDKVERSION $SDK_INCLUDE_OS $SYSROOT_OS
Compile armv7 $SDKVERSION $SDK_INCLUDE_OS $SYSROOT_OS

###########################################################################
#   Combine binaries into a single fat file
#
lipo -create arm64/lib/libidn.a armv7/lib/libidn.a x86_64/lib/libidn.a -output libidn.a

rm -rf src x86_64 arm64 armv7
