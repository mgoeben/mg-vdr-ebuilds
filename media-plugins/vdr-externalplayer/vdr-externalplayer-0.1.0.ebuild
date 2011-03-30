# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

RESTRICT="mirror"

inherit vdr-plugin

DESCRIPTION="VDR Plugin: use external programs to play some media files"
HOMEPAGE="http://sourceforge.net/projects/externalplayer"
SRC_URI="mirror://sourceforge/${VDRPLUGIN}/${P}.tar.gz"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND=">=media-video/vdr-1.3.21"

src_unpack() {
	vdr-plugin_src_unpack
	epatch "${FILESDIR}/${P}-gentoo.diff"
}

src_install() {
	vdr-plugin_src_install

	insinto /etc/vdr/plugins/externelplayer
	doins examples/externalplayer.conf
}
