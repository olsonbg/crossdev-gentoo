#Installing a Cross-compiling toolchain on Gentoo Linux

These instructions explain how to install a toolchain for compiling 32bit
and 64bit windows programs using Gentoo Linux and the
[crossdev](https://packages.gentoo.org/package/sys-devel/crossdev) tool.
Most of the steps in this instruction should be either performed as _root_,
or with a _sudo_ prefix.

I install toolchains for both 32bit (the *i686-pc-mingw32* target) and 64bit
(the *x86_64-pc-mingw32* target) windows. The instructions below include
commands to install both targets, however, if you wish to install just one
environment, feel free to skip the commands with the other.


## Crossdev Repository

First, we need to make a repository for portage and crossdev to store
package information. I place all my local repositories in the
`/usr/local/portage` directory, with each local repository as a
subdirectory. I call my crossdev repository *local-crossdev*, and it is
stored in `/usr/local/portage/crossdev.` To tell portage about this setup,
create `/usr/portage/repos.conf/local-crossdev.conf` with the following
contents:

```bash
[local-crossdev]
priority = 9999
masters = gentoo
auto-sync = no
location = /usr/local/portage/crossdev
```

Create the directory pointed to by the *location* parameter:

```bash
mkdir -p /usr/local/portage/crossdev
```

## Fresh install

Whenever a new _gcc_ version is released (made stable by crossdev), I like
to completely remove my old toolchain environment and start fresh. This
helps clean out some libraries that I need to install manually (like
_boost_), that portage isn't aware of. So let's start off by deleting the
old environment(s).

```bash
crossdev -C x86_64-pc-mingw32
crossdev -C i686-pc-mingw32
```

If crossdev asks if you want to delete the directory, answer _yes_.

## Initialize new environment

Setup in new toolchain environment(s) with:

```bash
crossdev -t x86_64-pc-mingw32 --stable --init-target -oO /usr/local/portage/crossdev
crossdev -t i686-pc-mingw32 --stable --init-target -oO /usr/local/portage/crossdev
```

where the directory after *-oO* should be the same as the *location*
parameter in [repo.conf](#crossdev-repository)

To use only packages from the stable branch, edit
`/usr/<target>/etc/portage/make.conf` and remove the unstable branch from
ACCEPT_KEYWORDS (~amd64, ~x86). The \<target\> tag should be replaced with
*x86_64-pc-mingw32*, *i686-pc-mingw32*, or any other target you wish to
install.

Make sure `gcc` is **not** compiled with the *sanitize* flag.

```bash
echo "cross-x86_64-pc-mingw32/gcc -sanitize" >> /etc/portage/package.use/crossdev
echo "cross-i686-pc-mingw32/gcc -sanitize" >> /etc/portage/package.use/crossdev
```

## Install environment

Now we can finally install the environment. Issue the following commands and
wait for them to complete.

```bash
crossdev -t x86_64-pc-mingw32 --stable -oO /usr/local/portage/crossdev
crossdev -t i686-pc-mingw32 --stable -oO /usr/local/portage/crossdev
```

## Extra packages

### bzip2

Bzip2 fails to compile for _i686-pc-mingw32_, the `ftello()` and `fseeko()`
routines must be changed to `ftello64()` and `fseeko64(),` respectively. To
do this, we will instruct portage to apply a patch when it installs bzip2.
First, make the directory structure where the patch will be placed:

```bash
mkdir -p /usr/i686-pc-mingw32/etc/portage/patches/app-arch/bzip2
```

and now copy the patch from
[bzip2/ftello64-fseeko64.patch](bzip2/ftello64-fseeko64.patch) into the
newly created directory.

```bash
cp bzip2/ftello64-fseeko64.patch /usr/i686-pc-mingw32/etc/portage/patches/app-arch/bzip2/
```

We also need to little script to instruct portage to apply our patch. Copy
bashrc from [bzip2/bashrc](bzip2/bashrc):

```bash
cp -p bzip2/bashrc /usr/i686-pc-mingw32/etc/portage/bashrc
```

That should let bzip2 install when emerging the [Boost library](#boost-library)

### Boost library

Boost will fail to compile with emerge, but this will
install dependencies like zlib and bzip2, and download the tarball to
portage DISTDIR for us.

```bash
USE="static-libs" ARCH=amd64 x86_64-pc-mingw32-emerge -avt boost
USE="static-libs" ARCH=x86   i686-pc-mingw32-emerge   -avt boost
```

Let `emerge` run until it fails on _boost_, all the required packages should
then be installed and we can go ahead and [install _boost_
manually](#manually-install-boost).

As a side note, it is convenient to know a way to show which packages have
been installed via emerge into our toolchain environments:

```bash
ROOT=/usr/x86_64-pc-mingw32 eix -I --only-names
ROOT=/usr/i686-pc-mingw32   eix -I --only-names
```
#### Manually install Boost
Extract the boost tarball that was downloaded into portage DISTDIR.
```bash
tar -xjf boost_1_56_0.tar.bz2
```
The name of your boost tarball may be different than shown here, if you have
a different version. Extract whatever version emerge downloaded for you.

Go into the directory that was extracted
```bash
cd boost_1_56_0
```
Again, the directory name may be different than yours if you got another
version of boost.

Now, to help install boost I have a little script which I call
[crossdev-boost.sh](crossdev-boost.sh). Run that script while still in the
boost extracted directory and it will guide you through the compiling and
installation process. Run the script multiple times to install for more
toolchain environments. If you downloaded `crossdev-boost.sh` into your home
directory, then use
```bash
~/crossdev-boost.sh
```

### winpthreads

To install winpthreads, first download the latest version of
[MinGW-w64](http://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release).
Then extract the package, compile winpthreads, and install following these
instructions (replace v3.2.0 with the version you downloaded):

```bash
tar -xjf mingw-w64-v3.2.0.tar.bz2
cd mingw-w64-v3.2.0/mingw-w64-libraries/winpthreads
TARGET=x86_64-pc-mingw32 && ./configure --prefix=/usr/$TARGET/usr --host=$TARGET --target=$TARGET --enable-static --disable-shared
make
sudo make install
```

Make sure *TARGET* is set appropriately.

## CMake

To cross-compile with cmake use the appropriate [toolchain](cmake/) file and
invoke cmake with

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=x86_64-pc-mingw32.cmake ...
```

replacing *...* with the cmake parameters needed for your particular project,
and *x86_64-pc-mingw32.cmake* with the file downloaded from
[toolchain](cmake/).

