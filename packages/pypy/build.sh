TERMUX_PKG_HOMEPAGE=https://pypy.org
TERMUX_PKG_DESCRIPTION="A fast, compliant alternative implementation of Python"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
_MAJOR_VERSION=2.7
TERMUX_PKG_VERSION=${_MAJOR_VERSION}-v7.3.6
TERMUX_PKG_SRCURL=https://downloads.python.org/pypy/pypy${TERMUX_PKG_VERSION}-src.tar.bz2
TERMUX_PKG_SHA256=0114473c8c57169cdcab1a69c60ad7fef7089731fdbe6f46af55060b29be41e4
TERMUX_PKG_BUILD_DEPENDS="python2, perl"
TERMUX_PKG_DEPENDS="libxml2, libexpat, tcl, tk, xorgproto"
TERMUX_PKG_RECOMMENDS="clang, make, pkg-config, openssl"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BLACKLISTED_ARCHES="arm"

# http://pypy.readthedocs.org/en/latest/config/commandline.html

if [ "$TERMUX_ON_DEVICE_BUILD" = "false" ]; then
	termux_error_exit "Package '$TERMUX_PKG_NAME' does not currently support cross compile."
fi

termux_step_make() {
	# pypy needs pypy or python2 interpreter
	# python2 does not have built-in sandbox
	python3 -m venv .venv
	. .venv/bin/activate
	python --version
	pip install virtualenv
	virtualenv -p "$(command -v python2)" .venv

	. .venv/bin/activate
	python --version

	#pip install -r requirements.txt
	#pip install cffi hypothesis enum34
	pip install pycparser

	export CFLAGS+=" -DBIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD"
	cd "$TERMUX_PKG_SRCDIR/pypy/goal"
	python2 ../../rpython/bin/rpython --make-jobs "$TERMUX_MAKE_PROCESSES" -Ojit targetpypystandalone.py

	cd "$TERMUX_PKG_SRCDIR"
	PYTHONPATH=. pypy/goal/pypy-c lib_pypy/pypy_tools/build_cffi_imports.py
}

termux_step_make_install() {
	cd ./pypy/tool/release
	./package.py --archive-name=pypy --targetdir "$TERMUX_PKG_SRCDIR"

	cd "$TERMUX_PKG_SRCDIR"
	tar -xvf pypy.tar.bz2 -C "$TERMUX_PREFIX/lib"

	ln -sf "$TERMUX_PREFIX/lib/pypy/bin/pypy" "$TERMUX_PREFIX/bin/pypy"
	ln -sf "$TERMUX_PREFIX/lib/pypy/bin/libpypy-c.so" "$TERMUX_PREFIX/lib/libpypy-c.so"
	rm -f ${TERMUX_PREFIX}/lib/pypy/bin/*.debug
	deactivate
}
