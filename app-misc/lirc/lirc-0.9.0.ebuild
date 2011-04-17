# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-misc/lirc/lirc-0.8.7_pre1.ebuild,v 1.1 2010/05/21 02:47:00 beandog Exp $

inherit eutils linux-mod flag-o-matic autotools

DESCRIPTION="decode and send infra-red signals of many commonly used remote controls"
HOMEPAGE="http://www.lirc.org/"

MY_P=${PN}-${PV/_/-}

if [[ "${PV/_pre/}" = "${PV}" ]]; then
	SRC_URI="mirror://sourceforge/lirc/${MY_P}.tar.bz2"
else
	SRC_URI="http://www.lirc.org/software/snapshots/${MY_P}.tar.bz2"
fi

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE="debug doc X hardware-carrier transmitter"

S="${WORKDIR}/${MY_P}"

RDEPEND="
	X? (
		x11-libs/libX11
		x11-libs/libSM
		x11-libs/libICE
	)
	"

# adding only compile-time depends
DEPEND="${RDEPEND} ${DEPEND}
	virtual/linux-sources
	"

# adding only run-time depends
RDEPEND="${RDEPEND}
	"

pkg_setup() {

	ewarn "If your LIRC device requires modules, you'll need MODULE_UNLOAD"
	ewarn "support in your kernel."

	linux-mod_pkg_setup

	# set default configure options
	MY_OPTS=""
	LIRC_DRIVER_DEVICE="/dev/lirc0"

	MY_OPTS="--with-driver=userspace"

	use hardware-carrier && MY_OPTS="${MY_OPTS} --without-soft-carrier"
	use transmitter && MY_OPTS="${MY_OPTS} --with-transmitter"

	# Setup parameter for linux-mod.eclass
	MODULE_NAMES="lirc(misc:${S})"
	BUILD_TARGETS="all"

	ECONF_PARAMS="	--localstatedir=/var
					--with-syslog=LOG_DAEMON
					--enable-sandboxed
					--with-kerneldir=${KV_DIR}
					--with-moduledir=/lib/modules/${KV_FULL}/misc
					$(use_enable debug)
					$(use_with X x)
					${MY_OPTS}"

	einfo
	einfo "lirc-configure-opts: ${MY_OPTS}"
	elog  "Setting default lirc-device to ${LIRC_DRIVER_DEVICE}"

	filter-flags -Wl,-O1

	# force non-parallel make, Bug 196134
	#MAKEOPTS="${MAKEOPTS} -j1"
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	# Rip out dos CRLF
	edos2unix contrib/lirc.rules

	# respect CFLAGS
	sed -i -e 's:CFLAGS="-O2:CFLAGS=""\n#CFLAGS="-O2:' configure.ac

	# setting default device-node
	local f
	for f in configure.ac acconfig.h; do
		[[ -f "$f" ]] && sed -i -e '/#define LIRC_DRIVER_DEVICE/d' "$f"
	done
	echo "#define LIRC_DRIVER_DEVICE \"${LIRC_DRIVER_DEVICE}\"" >> acconfig.h

	eautoreconf
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	newinitd "${FILESDIR}"/lircd-0.8.6 lircd
	newinitd "${FILESDIR}"/lircmd lircmd
	newconfd "${FILESDIR}"/lircd.conf.2 lircd

	insinto /etc/modprobe.d/
	newins "${FILESDIR}"/modprobed.lirc lirc.conf

	newinitd "${FILESDIR}"/irexec-initd-0.8.6-r2 irexec
	newconfd "${FILESDIR}"/irexec-confd irexec

	if use doc ; then
		dohtml doc/html/*.html
		insinto /usr/share/doc/${PF}/images
		doins doc/images/*
	fi

	insinto /usr/share/lirc/remotes
	doins -r remotes/*

	keepdir /var/run/lirc /etc/lirc
	if [[ -e "${D}"/etc/lirc/lircd.conf ]]; then
		newdoc "${D}"/etc/lirc/lircd.conf lircd.conf.example
	fi
}

pkg_preinst() {
	linux-mod_pkg_preinst

	local dir="${ROOT}/etc/modprobe.d"
	if [[ -a "${dir}"/lirc && ! -a "${dir}"/lirc.conf ]]; then
		elog "Renaming ${dir}/lirc to lirc.conf"
		mv -f "${dir}/lirc" "${dir}/lirc.conf"
	fi

	# copy the first file that can be found
	if [[ -f "${ROOT}"/etc/lirc/lircd.conf ]]; then
		cp "${ROOT}"/etc/lirc/lircd.conf "${T}"/lircd.conf
	elif [[ -f "${ROOT}"/etc/lircd.conf ]]; then
		cp "${ROOT}"/etc/lircd.conf "${T}"/lircd.conf
		MOVE_OLD_LIRCD_CONF=1
	elif [[ -f "${D}"/etc/lirc/lircd.conf ]]; then
		cp "${D}"/etc/lirc/lircd.conf "${T}"/lircd.conf
	fi

	# stop portage from touching the config file
	if [[ -e "${D}"/etc/lirc/lircd.conf ]]; then
		rm -f "${D}"/etc/lirc/lircd.conf
	fi
}

pkg_postinst() {
	linux-mod_pkg_postinst

	# copy config file to new location
	# without portage knowing about it
	# so it will not delete it on unmerge or ever touch it again
	if [[ -e "${T}"/lircd.conf ]]; then
		cp "${T}"/lircd.conf "${ROOT}"/etc/lirc/lircd.conf
		if [[ "$MOVE_OLD_LIRCD_CONF" = "1" ]]; then
			elog "Moved /etc/lircd.conf to /etc/lirc/lircd.conf"
			rm -f "${ROOT}"/etc/lircd.conf
		fi
	fi

	ewarn "The new default location for lircd.conf is inside of"
	ewarn "/etc/lirc/ directory"

}
