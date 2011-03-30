# Copyright 2003-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/vdr-control/vdr-control-0.0.2a-r1.ebuild,v 1.3 2005/12/03 10:38:28 zzam Exp $

IUSE=""
inherit vdr-plugin eutils

RESTRICT="mirror"
DESCRIPTION="Video Disk Recorder telnet-OSD PlugIn"
HOMEPAGE="http://ricomp.de/vdr/"
SRC_URI="http://ricomp.de/vdr/${P}.tgz
		mirror://vdrfiles/${PN}/${P}.tgz"
KEYWORDS="~x86 ~amd64"
SLOT="0"
LICENSE="GPL-2"

DEPEND=">=media-video/vdr-1.2.0"

PATCHES="${FILESDIR}/${P}-uint64.diff
${FILESDIR}/vdr-control-const_char_fix.diff
"

src_unpack() {
	vdr-plugin_src_unpack
	if
	has_version ">=media-video/vdr-1.3.18" ;
	then
		einfo "applying VDR >= 1.3.18 patch"
		epatch  "${FILESDIR}/control-vdr-1.3.18.diff"
	fi
}
