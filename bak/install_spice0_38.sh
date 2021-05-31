#!/bin/bash

workdir=$(pwd)

prefix=/spice
builddir=$workdir/build
buildcoreid=16
packdir=$workdir/output

index=1

###   icc 与   gcc 编译
# if [[ "$1"x == "gcc"x ]];then
# 	export CC=gcc
# 	export LD=ld
# 	export AR=ar
# 	export CXX=g++
# 	export CFLAGS="-O3 -DWITH_IPP -I$IPPROOT/include"
# 	make clean
# 	make -j16 --always-make
# fi
#
# if [[ "$1"x == "icc"x ]];then
# 	export CC=icc
# 	export LD=xild
# 	export AR=xiar
# 	export CXX=icpc
# 	export CFLAGS="-O3 -ipo -DWITH_IPP -I$IPPROOT/include"
# 	make clean
# 	make -j16 --always-make
# fi

export CFLAGS="-O2"

function showErr() {
    echo -e "\033[31m $1 \033[0m"
}

function showTip() {
    echo -e "\033[33m Step $index: $1 \033[0m"
    (( index++ ))
}

function checkresult() {
    if [[ $1 != 0 ]]; then
        showErr "Build $2  error!!! "
        rm -rf $builddir/$2
        echo "$builddir/$2"
        exit -1
    fi

    if [[ "$3"x == "install"x ]]; then
        echo -e "\033[34m Build $2  success!!! \033[0m"
    fi
}

function install_dependent_package() {
    while read line; do
        apt install -y $line
    done < $workdir/new-depend.list
}

# install_dependent_package

function Deb_Pack() {
    mkdir -p $packdir/$object
    cd $builddir/$object
    echo $1 > description-pak ;\
    checkinstall -y -D --nodoc --exclude=/root --pakdir=$packdir/$object --install=no --backup=no
}


#     -------------------------------------------------------------------


object=libusb-1.0.23
if [[ ! -d "$builddir/$object" ]]; then
    showTip "Building $object ..."
    # if [[ 1 -eq $autoreconfflag ]]; then
	cd $workdir/$object
	autoreconf -ivf
	checkresult $? $object
	# fi
    mkdir -p $builddir/$object
	cd $builddir/$object
	$workdir/$object/configure \
	--prefix=$prefix        \
	--libdir=/lib/x86_64-linux-gnu
	checkresult $? $object
	make -j$buildcoreid
	checkresult $? $object
	make install
	checkresult $? $object install
	Deb_Pack $object
fi

#     -------------------------------------------------------------------
object=usbredir-0.8.0
if [[ ! -d "$builddir/$object" ]]; then
    showTip "Building $object ..."
    if [[ 1 -eq $autoreconfflag ]]; then
        cd $workdir/$object
        autoreconf -ivf
        checkresult $? $object
    fi
    mkdir -p $builddir/$object
    cd $builddir/$object
    $workdir/$object/configure \
    --prefix=$prefix 
    checkresult $? $object
    make -j$buildcoreid
    checkresult $? $object
    make install
    checkresult $? $object install
    Deb_Pack $object
fi

# # ------------------------------------------------------------
#--with-project=auto  
object=spice-gtk-0.38
showTip "Building $object ..."
# if [[ 1 -eq $autoreconfflag ]]; then
#     cd $workdir/$object
#     # autoreconf -ivf
#     checkresult $? $object
# fi
if [[ ! -d "$builddir/$object" ]]; then
    mkdir -p $builddir/$object
    cd $builddir/$object
    # CFLAGS="-O2" $workdir/$object/configure      \
    meson --buildtype=release \
    $workdir/$object      \
    --prefix=$prefix           \
    -Dshared=disabled         \
    -Dgstaudio=disabled       \
    -Dgstvideo=enabled        \
    -Dpulse=enabled           \
    -Dusbredir=enabled        \
    -Dcoroutine=gthread      \
    -Dsmartcard=disabled     \
    -Dwebdav=disabled         \
    -Dvala=enabled              \
    -Dpolkit=disabled         \
    -Dlz4=enabled           \
    -Dcelt051=enabled           \
    -Dusb-ids-path=./usb.ids \
    -Dopus=disabled 
    # -Dgtk=3.0             
    checkresult $? $object
else
    cd $builddir/$object
fi
ninja  
checkresult $? $object
ninja install
checkresult $? $object install
Deb_Pack $object



