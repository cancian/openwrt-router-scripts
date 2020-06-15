#!/usr/bin/env bash

# Constants
LOG="results/benchmark.log"
TIMESTAMP=$(date +%s)
TARGET_WD="/tmp/benchmark-${TIMESTAMP}"

# Core functions
function help() {
	echo "Usage: $0 <configuration> <dataset>"
}

echo -n > $LOG
function log() {
	echo " $(date +%H:%M)# $*"|tee -a $LOG
}

# Load configuration
if [ $# -gt 1 ]; then
	log "Loading configuration '$1'"
	source $1
else
	help
	exit 1
fi

# Debug mode
debug=$(echo $debug | tr "[A-Z]" "[a-z]")
if [[ $debug == "yes" ]]; then
	set -x
fi

# Check dataset
dset=${2%%.tgz}
if [ ! -f ${dset}.tgz ]; then
	log "error: couldn't find dataset '${dset}.tgz'"
	help
	exit 1
fi

function rcpy() {
	log "  - $1 $(du -sh $1|awk '{print $1}') >> ${target}"
	scp -r $1 ${target}:${TARGET_WD}/ &>>$LOG
}

function rfetch() {
	log "  - $1 >> $(pwd)"
	scp ${target}:${TARGET_WD}/$1 . &>>$LOG
}

function lcmd() {
	echo $* >> $LOG
	$* 2>&1|while read l;
	do
		log "  | $l"
	done
	return $?
}

function rcmd() {
	lcmd ssh -o StrictHostKeyChecking=no ${target} "$*"
	return $?
}

function wait_for_reachable() {
	UNREACHEABLE=$(( ! $1 ))
	while [ $UNREACHEABLE -ne "$1" ];
	do ping -q -c 1 $2 &> /dev/null; UNREACHEABLE=$?; sleep 1;
	done
}

function system_change() {
	sys_index=-1

	if [[ $1 == 'linux' ]]; then
		sys_index=0
	elif [[ $1 == 'freebsd' ]]; then
		sys_index=2
	fi


	if [[ $sys_index -ge 0 ]]; then
		rcmd sudo sysch $sys_index
	else
		log "error: Unknown target system for reboot: $1"
	fi
}

function wait_reboot() {
	wait_for_reachable 1 ${target}
	log "* '${target}' is down"
	wait_for_reachable 0 ${target}
	log "* '${target}' is up"

	# Wait for SSH Daemon
	while : ; do
		ssh -t ${target} 'exit 0' 2> /dev/null \
			&& break;
		sleep 5 \
			&& log "Waiting for SSH Daemon";
	done
}

function interrupt() {
	log "SIGINT caught, exitting."
	exit 1
}

trap interrupt SIGINT

# Write out test configuration
CONFIG="/tmp/measure.conf"
cat $1 > $CONFIG
echo "dset=\"$(basename ${dset})\"" >> $CONFIG

# No OS configured, do not reboot
[ -z ${systems} ] && systems=( - )

# Commence benchmarking
for os in ${systems[@]}; do
	rem_name=$(ssh ${target} uname)
	log "Benchmark commencing on ${target}/$rem_name"
	log "Remote directory ${TARGET_WD}"

	regex="[^:]+:[^:]+"
	if [[ $os =~ $regex ]]; then
		iface=${os##*:}
		os=${os%:$iface}
	else
		log "error: Wrong setup of operating system - interface pair in systems variable"
		continue
	fi

	if [ "$os" != "-" ] && [ "$rem_name" != "$os" ]; then
		if [ "${reboot}" == "yes" ]; then
			log "* rebooting '${target}' $rem_name -> $os"
			system_change $(echo $os | tr '[A-Z]' '[a-z]')
			wait_reboot
		else
			continue
		fi
		rem_name="$os"
	fi
	rcmd mkdir -p ${TARGET_WD}
	log "* uploading testbed"
	rcpy $CONFIG
	rcpy measure.sh
	log "* uploading modules"
	rcpy modules
	log "* uploading hooks"
	rcpy hooks
	log "* uploading dataset"
	rcpy ${dset}.tgz
	if [ "${netsetup:-yes}" != "no" ]; then
		log "* tweaking network"
		rcpy netsetup.sh
		rcmd sudo ${TARGET_WD}/netsetup.sh ${iface}
	fi
	log "* measuring"

	rcmd ${TARGET_WD}/measure.sh ${TARGET_WD}/measure.conf ${iface}

	# Fetch results
	result_name="$(echo ${rem_name}|tr '[A-Z]' '[a-z]')-$(basename ${dset})-${iface_name}"
	result_dir="results/${result_name}"
	result_file="${result_name}-$TIMESTAMP"
	rfetch results.tgz
	[ ! -d ${result_dir} ] && mkdir -p ${result_dir}
	if [ -f results.tgz ]; then
		mv results.tgz ${result_dir}/${result_file}.tgz

		# Post-test hooks
		if [ -d post ]; then
			for p in post/*.sh; do
				[ -x ${p} ] && lcmd ${p} $(pwd)/${result_dir}/${result_file}.tgz
			done
		fi
	fi

	# Save benchmark log for future reference
	cp $LOG ${result_dir}/${result_file}.log
done

# Debug mode off
if [[ $debug == "yes" ]]; then
	set +x
fi

