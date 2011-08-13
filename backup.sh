#!/bin/sh
#
# Rsync backup script
#
# (c) 2007 Tim Hemel tim at timit dot nl
#
# Usage:
#     backup.sh configfile
#
# See example.conf for config file Format.
#

RSYNC=/usr/local/bin/rsync
NUMKEEP=4
RSYNCOPTS="--stats --delete --force -vv -zaR -x --numeric-ids"
initialdir=backup-19700101-000000

list_backups()
{
	find . -name 'backup-*' -type d -exec basename {} \; > INDEX
}

list_failed()
{
	cp FAILED FAILED.bak
	cat INDEX FAILED.bak | sort | uniq -d > FAILED
	rm -f FAILED.bak
}

list_success()
{
	cat INDEX FAILED FAILED | sort | uniq -u > SUCCESS
}

# assumes we are in $BACKUPDIR
init_backup()
{
	# create initial dir if it does not exist
	if [ ! -d "$initialdir" ]
	then
		mkdir -p "$initialdir"
	fi
	touch FAILED
	# clean FAILED
	list_backups
	list_failed
	list_success
}

clean_backups() {
	numkeep=$1
	# get non-failed backups, except $initialdir
	grep -v $initialdir SUCCESS > CLEAN
	( cat CLEAN && ( cat CLEAN | tail -$numkeep ) ) | \
		sort | uniq -u | xargs -n 1 -I % rm -rf % %.err %.log
	rm -f CLEAN
}

exit_backup()
{
	rm -f SUCCESS INDEX
}

# assumes we are in $BACKUPDIR
do_backup()
{
	account="$1"
	backupdir="$2"
	# find latest non-failed backup
	latest=`tail -1 SUCCESS`
	current=backup-`date +%Y%m%d-%H%M%S`
	echo "Backup to $current relative to $latest"
	do_rsync "$account" "$latest" "$current" "$backupdir"
	exitcode=$?
	if [ $exitcode -ne 0 ]
	then
		echo "Backup of $account failed! (exit code $exitcode)"
		echo "$current" >> FAILED
		cat ${current}.err
	fi
}

# assumes we are in $BACKUPDIR
do_rsync()
{
	account="$1"
	previous="$2"
	current="$3"
	backupdir="$4"
	mkdir -p "$current"
	$RSYNC $RSYNCOPTS --link-dest="$backupdir/$previous" "$account" "$current" >> "$current.log" 2>> "$current.err"
}



# make_backup user@host:path/to/dir /path/to/backupdir num_keep
# /path/to/backupdir must be absolute path!
make_backup()
{
	src="$1"
	backupdir="$2"
	numkeep="$3"
	mkdir -p "$backupdir"
	cd "$backupdir" && init_backup && do_backup "$src" "$backupdir" && clean_backups $numkeep && exit_backup
}

config="$1"
if [ ! "$config" ]
then
	echo Need config file
	exit 1
fi

. "$config"

for m in $backup_modules
do
	eval src=\${backup_module_${m}_source}
	eval backupdir=\${backup_module_${m}_backupdir}
	eval numkeep=\${backup_module_${m}_numkeep:=${NUMKEEP}}
	if [ "$src" -a "$backupdir" ]
	then
		make_backup "$src" "$backupdir" $numkeep
	fi
done


