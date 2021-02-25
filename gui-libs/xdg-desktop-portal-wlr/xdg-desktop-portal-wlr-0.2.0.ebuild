# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit meson

DESCRIPTION="xdg-desktop-portal backend for wlroots"
HOMEPAGE="https://github.com/emersion/xdg-desktop-portal-wlr"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/emersion/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/emersion/${PN}/releases/download/v${PV}/${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0"
IUSE="basu elogind systemd"
REQUIRED_USE="^^ ( basu elogind systemd )"

DEPEND="
	>=media-video/pipewire-0.2.9:=
	dev-libs/wayland
	>=dev-libs/wayland-protocols-1.14:=
	basu? ( sys-libs/basu )
	elogind? ( >=sys-auth/elogind-237 )
	systemd? ( >=sys-apps/systemd-237 )
"
RDEPEND="
	${DEPEND}
	sys-apps/xdg-desktop-portal
"
BDEPEND="
	>=media-video/pipewire-0.2.9:=
	>=dev-libs/wayland-protocols-1.14
	>=dev-util/meson-0.47.0
	virtual/pkgconfig
"

src_configure() {
	use basu && sdbus=basu
	use elogind && sdbus=libelogind
	use systemd && sdbus=libsystemd

	local emesonargs=(
		"-Dwerror=false"
		-Dsd-bus-provider=$sdbus
	)

	meson_src_configure
}
