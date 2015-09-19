#!/bin/sh
#
# Run from the boost source directory.

if [ ! -d  tools/build ]; then
   echo "Can not find tools/build directory!";
   echo "Make sure you are at the root of the boost source tree";

   exit
fi

USERCFG=$(find ./tools/build -name user-config.jam)
# Copy the example user-config.jam to the boost build root directory.
[[ -f "$USERCFG" ]] && cp "$USERCFG" .

export BOOST_BUILD_PATH=$(pwd)

echo -n "Determining python root... "
PYTHON_ROOT=`python -c "import sys; print(sys.prefix)"`
echo $PYTHON_ROOT

# Find installed crossdev toolchains.

echo "Finding installed crossdev toolchains..."
TARGET=""
P=/etc/portage/package.use/cross-
B=( $(ls $P*|sed -e "s:$P::") )


if [ ${#B[@]} -gt 1 ]; then
	echo "Installed crossdev toolchains:"
	echo
	for i in $(seq 1 ${#B[@]}); do
		echo "$i) ${B[$[i-1]]}"
	done
	echo
	echo -n "Which toolchain should we install boost for [1-${#B[@]}]? "
	read SELECTION

	[[ $SELECTION -lt 1 ]] || [[ $SELECTION -gt ${#B[@]} ]] && exit
	TARGET=${B[$[SELECTION-1]]}
else
	TARGET=$B
fi

# Find installed gcc versions

echo "Finding gcc versions (MAJOR.MINOR) installed in $TARGET..."
GCCVER=""
G=$(equery -q list --format=\$version cross-$TARGET/gcc|sed -e 's/\([0-9]*\.[0-9]\)*\..*/\1/')

if [ ${#G[@]} -gt 1 ]; then
	echo "Installed gcc versions in $TARGET"
	echo
	for i in $(seq 1 ${#G[@]}); do
		echo "$i) ${G[$[i-1]]}"
	done
	echo
	echo -n "Which gcc version should we install boost for [1-${#G[@]}]? "
	read SELECTION
	[[ $SELECTION -lt 1 ]] || [[ $SELECTION -gt ${#G[@]} ]] && exit
	GCCVER=${G[$[SELECTION-1]]}
else
	GCCVER=$G
fi

echo
echo "Setting gcc version to ${GCCVER}, and target to ${TARGET}."
echo
echo "using gcc : ${GCCVER} : ${TARGET}-g++ ;" >> user-config.jam
#
# Now run the bootstrap
echo "Running the bootstrap..."
#
./bootstrap.sh --prefix=/usr/${TARGET}/usr --with-python-root=$PYTHON_ROOT
#
# Now build it.
echo "Building boost..."
#
./b2 -a -j3 --prefix=/usr/${TARGET}/usr --build-dir=build --layout=versioned --ignore-site-config target-os=windows threadapi=win32
#
# in stage/lib/, remove _win32 from the thread files.
#
echo "Renaming *_win32* files..."
for x in stage/lib/*_win32*; do mv -v "${x}" "${x/_win32/}"; done
#
# Now copy the library and include files to the crossdev
# system.
#
echo "Copying files to /usr/${TARGET}/usr/lib/"
cp stage/lib/libboost_* /usr/${TARGET}/usr/lib/
echo "Copying files to /usr/${TARGET}/usr/include/"
cp -R boost /usr/${TARGET}/usr/include/
#
#
# Done - Manual install of boost
echo "Done installing of boost for ${TARGET}."

