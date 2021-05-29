# Copyright 2003-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic multilib-minimal

DESCRIPTION="Libraries/utilities to handle ELF objects (drop in replacement for libelf)"
HOMEPAGE="http://elfutils.org/"
SRC_URI="https://sourceware.org/elfutils/ftp/${PV}/${P}.tar.bz2"

LICENSE="|| ( GPL-2+ LGPL-3+ ) utils? ( GPL-3+ )"
SLOT="0"
KEYWORDS="~amd64"
IUSE="bzip2 lzma nls static-libs test +threads +utils valgrind zstd"
REQUIRED_USE="test? ( utils )"

RDEPEND="
	!dev-libs/libelf
	>=sys-libs/zlib-1.2.8-r1[static-libs?,${MULTILIB_USEDEP}]
	bzip2? ( >=app-arch/bzip2-1.0.6-r4[static-libs?,${MULTILIB_USEDEP}] )
	elibc_musl? (
		sys-libs/argp-standalone
		sys-libs/fts-standalone
		sys-libs/obstack-standalone
		dev-libs/libbsd
	)
	lzma? ( >=app-arch/xz-utils-5.0.5-r1[static-libs?,${MULTILIB_USEDEP}] )
	zstd? ( app-arch/zstd:=[static-libs?,${MULTILIB_USEDEP}] )
"
DEPEND="
	${RDEPEND}
	valgrind? ( dev-util/valgrind )
"
BDEPEND="
	nls? ( sys-devel/gettext )
	>=sys-devel/flex-2.5.4a
	sys-devel/m4
"
RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}"/${PN}-0.175-disable-biarch-test-PR24158.patch
	"${FILESDIR}"/${PN}-0.177-disable-large.patch
	"${FILESDIR}"/${PN}-0.180-PaX-support.patch
	"${FILESDIR}"/musl/musl-error_h.patch
	"${FILESDIR}"/musl/musl-cdefs.patch
)

src_prepare() {
	default

	if ! use utils
	then
		sed -i '/src\//d' configure.ac || die
	fi

	eautoreconf

	if ! use static-libs
	then
		sed -i -e '/^lib_LIBRARIES/s:=.*:=:' -e '/^%.os/s:%.o$::' lib{asm,dw,elf}/Makefile.in || die
	fi
	# https://sourceware.org/PR23914
	sed -i 's:-Werror::' */Makefile.in || die
}

src_configure() {
	use test && append-flags -g #407135

	# Symbol aliases are implemented as asm statements.
	# Will require porting: https://gcc.gnu.org/PR48200
	filter-flags '-flto*'

	use elibc_musl && append-cflags -DFNM_EXTMATCH=0

	multilib-minimal_src_configure
}

multilib_src_configure() {
	myeconfflags=(
		"$(use_enable nls)"
		"$(use_enable threads thread-safety)"
		"$(use_enable valgrind)"
		"--disable-debuginfod"
		"--disable-libdebuginfod"
		"--program-prefix='eu-'"
		"--with-zlib"
		"$(use_with bzip2 bzlib)"
		"$(use_with lzma)"
		"$(use_with zstd)"
	)

	if tc-is-clang && ! use utils
	then
		myeconfflags+=( "ac_cv_c99=yes" )
	fi

	ECONF_SOURCE="${S}" econf "${myeconfflags[@]}"
}

multilib_src_compile() {
	if use utils
	then
		emake
	else
		for i in backends lib{,ebl,cpu,dwelf,dwfl,elf,dw,asm}
		do
			emake -C "$i"
		done
	fi
}

multilib_src_test() {
	env	LD_LIBRARY_PATH="${BUILD_DIR}/libelf:${BUILD_DIR}/libebl:${BUILD_DIR}/libdw:${BUILD_DIR}/libasm" \
		LC_ALL="C" \
		emake check VERBOSE=1
}

multilib_src_install() {
	if use utils
	then
		emake DESTDIR="${D}" install
	else
		for i in backends lib{,ebl,cpu,dwelf,dwfl,elf,dw,asm}
		do
			emake -C "$i" DESTDIR="${D}" install
		done

		insinto /usr/lib/pkgconfig
		doins config/libdw.pc
		doins config/libelf.pc
	fi
}

multilib_src_install_all() {
	einstalldocs
	dodoc NOTES
}
