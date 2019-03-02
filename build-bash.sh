#!/bin/bash
echored () {
  echo "${TEXTRED}$1${TEXTRESET}"
}
echogreen () {
  echo "${TEXTGREEN}$1${TEXTRESET}"
}
usage () {
  echo " "
  echored "USAGE:"
  echogreen "To check patches are correct: check"
  echogreen "VER argument below must be applied with check"
  echored "Otherwise, Valid arguments are:"
  echogreen "VER=      (Default: 5.0)"
  echogreen "ARCH=     (Default: arm) (Valid Arch values: arm, arm64, aarch64, x86, i686, x64, x86_64)"
  echo " "
  exit 1
}
check_patches () {
  echogreen "Checking patches"
  [ -z $VER ] && { echored "Version not defined!"; exit 1; }
  [[ $(wget -S --spider http://mirrors.kernel.org/gnu/bash/bash-$VER.tar.gz 2>&1 | grep 'HTTP/1.1 200 OK') ]] || { echored "Invalid Bash VER! Check this: http://mirrors.kernel.org/gnu/bash/ for valid versions!"; usage; }
  setup_bash
  apply_patches
  echogreen "Patches are good!"
  exit 0
}
apply_patches() {
  cd $DIR/bash_android/bash-$VER
  echogreen "Applying patches"
  for i in {001..050}; do
    wget https://mirrors.kernel.org/gnu/bash/bash-$VER-patches/bash$PVER-$i 2>/dev/null
    if [ -f "bash$PVER-$i" ]; then
      patch -p0 -i bash$PVER-$i
      rm -f bash$PVER-$i
    else
      break
    fi
  done
  for i in $DIR/patches/*; do
    PFILE=$(basename $i)
    cp -f $i $PFILE
    sed -i "s/4.4/$VER/g" $PFILE    
    patch -p0 -i $PFILE
    [ $? -ne 0 ] && { echored "Patching failed! Did you verify line numbers? See README for more info"; exit 1; }
    rm -f $PFILE
  done
  cd ..
}
setup_bash() {
  mkdir $DIR/bash_android 2>/dev/null
  cd $DIR/bash_android
  echogreen "Fetching bash $VER"
  rm -rf bash-$VER Toolchains
  [ -f "bash-$VER.tar.gz" ] || wget http://mirrors.kernel.org/gnu/bash/bash-$VER.tar.gz
  tar -xf bash-$VER.tar.gz
}

TEXTRESET=$(tput sgr0)
TEXTGREEN=$(tput setaf 2)
TEXTRED=$(tput setaf 1)
DIR=`pwd`
COMPILER=NDK
NDK=r19b
CHECK=false
OIFS=$IFS; IFS=\|; 
while true; do
  case "$1" in
    -h|--help) usage;;
    "") shift; break;;
    VER=*|ARCH=*) eval $1; shift;;
    check) CHECK=true; shift;;
    *) echored "Invalid option: $1!"; usage;;
  esac
done
IFS=$OIFS

$CHECK && check_patches
[ -z $VER ] && VER=5.0
case $VER in
  5*) rm -rf $DIR/patches; cp -rf $DIR/patches_5 $DIR/patches;;
  *) rm -rf $DIR/patches; cp -rf $DIR/patches_4 $DIR/patches;;
esac
[[ $(wget -S --spider http://mirrors.kernel.org/gnu/bash/bash-$VER.tar.gz 2>&1 | grep 'HTTP/1.1 200 OK') ]] || { echored "Invalid Bash VER! Check this: http://mirrors.kernel.org/gnu/bash/ for valid versions!"; usage; }
PVER=$(echo $VER | sed 's/\.//')
[ -z $ARCH ] && ARCH=arm
case $ARCH in
  arm64|aarch64) target_host=aarch64-linux-gnu; COMPILER=LINARO;;
  arm) target_host=arm-linux-androideabi;;
  x64|x86_64) target_host=x86_64-linux-android; ARCH=x86_64;;
  x86|i686) target_host=i686-linux-android; ARCH=x86;;
  *) echored "Invalid ARCH entered!"; usage;;
esac

setup_bash

# Apply bash patches - Android patches originally by Alexander Gromnitsky, ATechnoHazard, koro666, and Termux @Github
apply_patches

if [ "$COMPILER" == "NDK" ]; then
  # Set up Android NDK
  echogreen "Fetching Android NDK $NDK"
  [ -f "android-ndk-$NDK-linux-x86_64.zip" ] || wget https://dl.google.com/android/repository/android-ndk-$NDK-linux-x86_64.zip
  [ -d "android-ndk-$NDK" ] || unzip -o android-ndk-$NDK-linux-x86_64.zip
  echogreen "Setting Up Android NDK $NDK"
  [ -d "Toolchains-$ARCH" ] || python android-ndk-$NDK/build/tools/make_standalone_toolchain.py --arch $ARCH --api 21 --install-dir Toolchains-$ARCH --force

  # Add the standalone toolchain to the search path.
  cd bash-$VER
  export PATH=$DIR/bash_android/Toolchains-$ARCH/bin:$PATH

  # Tell configure what tools to use.
  export AR=$target_host-ar
  export AS=$target_host-clang
  export CC=$target_host-clang
  export CXX=$target_host-clang++
  export LD=$target_host-ld
  export STRIP=$target_host-strip
  
  # Configure - valid arguments found from termux-packages and bash-on-android github repos 
  echogreen "Configuring"
  ./configure --host=$target_host --disable-nls --enable-static-link --without-bash-malloc bash_cv_dev_fd=whacky bash_cv_getcwd_malloc=yes --enable-largefile --enable-alias --enable-history --enable-readline --enable-multibyte --enable-job-control --enable-array-variables CFLAGS="-g -O2 -static" LDFLAGS="-g -O2 -static"
  [ $? -eq 0 ] || { echored "Configure failed!"; exit 1; }
else
  # Set up Linaro gcc
  echogreen "Setting up linaro gcc"
  [ -f gcc-linaro-7.4.1-2019.02-x86_64_$target_host.tar.xz ] || wget https://releases.linaro.org/components/toolchain/binaries/latest-7/$target_host/gcc-linaro-7.4.1-2019.02-x86_64_$target_host.tar.xz
  [ -d gcc-linaro-7.4.1-2019.02-x86_64_$target_host ] || tar -xf gcc-linaro-7.4.1-2019.02-x86_64_$target_host.tar.xz

  # Add the standalone toolchain to the search path.
  cd bash-$VER
  export PATH=$DIR/bash_android/gcc-linaro-7.4.1-2019.02-x86_64_$target_host/bin:$PATH
  
  # Configure - valid arguments found from termux-packages and bash-on-android github repos 
  echogreen "Configuring"
  ./configure --host=$target_host --disable-nls --enable-static-link --without-bash-malloc bash_cv_dev_fd=whacky bash_cv_getcwd_malloc=yes --enable-largefile --enable-alias --enable-history --enable-readline --enable-multibyte --enable-job-control --enable-array-variables CFLAGS="-g -O2 -static" LDFLAGS="-g -O2 -static"
  [ $? -eq 0 ] || { echored "Configure failed!"; exit 1; }
fi

# Build bash
echogreen "Building"
make

[ $? -eq 0 ] && { mv -f bash $DIR/bash-$ARCH; $target_host-strip $DIR/bash-$ARCH; echogreen "Bash binary built sucessfully and can be found at: $DIR"; }
