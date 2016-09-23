#!/bin/bash


function abspath() {
  (
  cd $(dirname $1)      # or  cd ${1%/*}
  echo $PWD 			# or  echo $PWD/${1##*/}
  )
}

DIR=`abspath $0`
LORAMACNODE="$DIR/../LoRaMac-node"
DIRCOMMITS="commits"
DIRPATCH="patch"

echo "DIR $DIR"

cd $LORAMACNODE
echo "Enter `pwd`"

#ip addr show eth0 | sed -n "s/\s\+inet\s\?\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p"
#9c28a9307afd7a10da267da4d101868696588db1
LASTCOMMIT=`git log -n 1 | sed -n "s/commit\s\([0-9a-f]\{40\}\).*/\1/p"`
LASTCOMMITDATE=`git log -n1 --format="%at"`
echo $LASTCOMMIT

if [ -z $LASTCOMMIT ]; then
	echo "No commit found"
else
	echo "Commit found"
fi

# Back to liblorawan directory
cd $DIR
echo "Switch bakc to `pwd`"

if [ ! -e $DIRCOMMITS ]; then
	mkdir -p $DIRCOMMITS
fi

if [ -e $DIRCOMMITS/$LASTCOMMIT ]; then
	echo -e "duplicated commits $LASTCOMMIT\nAbort"
	exit 0
fi

mkdir -p $DIRCOMMITS/$LASTCOMMIT/src
mkdir -p $DIRCOMMITS/$LASTCOMMIT/src/mac
mkdir -p $DIRCOMMITS/$LASTCOMMIT/src/misc
mkdir -p $DIRCOMMITS/$LASTCOMMIT/src/radio
mkdir -p $DIRCOMMITS/$LASTCOMMIT/src/system
mkdir -p $DIRCOMMITS/$LASTCOMMIT/template


DIRSOURCE=$LORAMACNODE
DIRTARGET=$DIRCOMMITS/$LASTCOMMIT

cp -rf $DIRSOURCE/src/mac/{LoRaMac-api-v3.*,LoRaMac.*,LoRaMacCrypto.*,LoRaMacTest.h,LoRaMac-definitions.h} $DIRTARGET/src/mac/
cp -rf $DIRSOURCE/src/boards/mcu/stm32/utilities.* $DIRTARGET/src/misc/
cp -rf $DIRSOURCE/src/radio/* $DIRTARGET/src/radio/
cp -rf $DIRSOURCE/src/system/{delay.*,gpio.*,timer.*,spi.h,crypto} $DIRTARGET/src/system/
cp -rf $DIRSOURCE/readme.md  $DIRTARGET/readme.lw.md
cp -rf $DIRSOURCE/LICENSE.txt $DIRTARGET/
cp -rf $DIRSOURCE/src/boards/SensorNode/{board.*,rtc-board.*,spi-board.*,gpio-board.*,pinName*,sx1276-board.*} $DIRTARGET/template/

echo "Convert files to DOS format"
#find . -type f -print0 | xargs -0 -n 1 -P 4 unix2dos
find $DIRCOMMITS/$LASTCOMMIT -type f -print0 | xargs -0 -n 1 -P 4 unix2dos -c 7bit

DIRTOPCOMMIT0=`find $DIRCOMMITS/latest* -maxdepth 0 -type d`

if [ -z $DIRTOPCOMMIT0 ]; then
	DIRTOPCOMMIT=$DIRCOMMITS/latest$LASTCOMMIT
else
	DIRTOPCOMMIT=$DIRTOPCOMMIT0
fi

if [ ! -e $DIRTOPCOMMIT ]; then
	echo -e "Create top commit directory"
	mkdir $DIRTOPCOMMIT
	cp -rf $DIRTARGET/* $DIRTOPCOMMIT/
fi

if [ ! -e $DIRPATCH ]; then
	mkdir -p $DIRPATCH
fi

CURCOMMIT=`echo "DIRTOPCOMMIT $DIRTOPCOMMIT" | sed -n "s/.*latest\(.*\)\$/\1/p"`
echo "DIRTOPCOMMIT $DIRTOPCOMMIT"
echo "CURCOMMIT $CURCOMMIT"

if [ "$CURCOMMIT" = "$LASTCOMMIT" ]; then
	echo "LASTCOMMIT equals to CURCOMMIT"
	#exit 0
fi

diff -uNrp  $DIRTOPCOMMIT $DIRTARGET > $DIRPATCH/"$CURCOMMIT-$LASTCOMMIT.patch"

rm -rf $DIRTOPCOMMIT

DIRTOPCOMMIT=$DIRCOMMITS/latest$LASTCOMMIT
mkdir $DIRTOPCOMMIT
cp -rf $DIRTARGET/* $DIRTOPCOMMIT/
