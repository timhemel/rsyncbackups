include base.mk

SIPAMA_NAME?=rsyncbackups
SIPAMA_VERSION=1.0
NAME=$(SIPAMA_NAME)
VERSION=$(SIPAMA_VERSION)

INSTDIR=${PREFIX}/rsyncbackups
ifndef BINDIR
BINDIR=$$HOME/bin
endif

do-install:
	mkdir -p ${INSTDIR}
	cp backup.sh ${INSTDIR}
	chmod +x ${INSTDIR}/backup.sh
	ln -sf ${INSTDIR}/backup.sh ${BINDIR}

post-install:
	echo BINDIR=${BINDIR} >> ${SIPAMA_DBDIR}/${NAME}

do-deinstall:
	rm -f ${INSTDIR}/backup.sh
	rmdir ${INSTDIR}
	rm -f ${BINDIR}/backup.sh


