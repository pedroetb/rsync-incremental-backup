#!/bin/bash

# Configuration variables (change as you wish)
src="/data"
dst="/nfs/neptune/Backups/rsyncIncremental/mars/datavol-data"
backupDepth=7
timeout=1800
pathBak0="data"
partialFolderName=".rsync-partial"
rotationLockFileName=".rsync-rotation-lock"
pathBakN="backup"
nameBakN="backup"
logName="rsync-incremental-backup_$(date -Id)_$(date +%H-%M-%S).log"
tempLogFolderName=".rsync-incremental-backup"
logFolderName="log"

# Combinate previously defined variables for use (don't touch this)
tempLogBasePath="${HOME}/${tempLogFolderName}"
tempLogPath="${tempLogBasePath}/local_${dst//[\/]/\\}"
bak0="${dst}/${pathBak0}"
partialFolderPath="${dst}/${partialFolderName}"
rotationLockFilePath="${dst}/${rotationLockFileName}"
logPath="${dst}/${pathBakN}/${logFolderName}"
logFile="${tempLogPath}/${logName}"

# Prepare log file
mkdir -p ${tempLogPath}
touch ${logFile}

writeToLog() {
	echo -e "$1" | tee -a ${logFile}
}

writeToLog "********************************"
writeToLog "*                              *"
writeToLog "*   rsync-incremental-backup   *"
writeToLog "*                              *"
writeToLog "********************************"

# Prepare backup paths
i=1
while [ $i -le $backupDepth ]
do
	export bak$i="${dst}/${pathBakN}/${nameBakN}.$i"
	true $((i = i + 1))
done

# Prepare main rsync configuration
rsyncFlags="-achlv --info=progress2 --timeout=${timeout} --delete --partial-dir=${partialFolderPath} \
--link-dest=${bak1}/ --log-file=${logFile} --exclude=${tempLogBasePath} --chmod=+r \
-l --exclude tmp/ --exclude *[Cc]ache*/ --exclude **~ --exclude lost+found/ --exclude *[Tt]rash*/ --exclude **/.gvfs/ --exclude VirtualMachines/ --exclude docker/ --exclude .Trash-1000/ --exclude *[Ss]nap*/  --exclude bin/openshift/ --exclude *oc*/"

# Prepare log rsync configuration
logRsyncFlags="-rhv --remove-source-files --exclude=${logName} --log-file=${logFile}"

writeToLog "\n[$(date -Is)] You are going to backup"
writeToLog "\tfrom:  ${src}"
writeToLog "\tto:    ${bak0}"
writeToLog "\tflags: ${rsyncFlags}"

# Prepare paths at destination
mkdir -p ${dst} ${logPath}

writeToLog "\n[$(date -Is)] Old logs sending begins\n"

# Send old pending logs to destination
rsync ${logRsyncFlags} ${tempLogPath}/ ${logPath}/

writeToLog "\n[$(date -Is)] Old logs sending finished"

# Rotate backups if last rsync succeeded ..
if ([ ! -d ${partialFolderPath} ] && [ ! -e ${rotationLockFilePath} ])
then
	# .. and there is previous data
	if [ -d ${bak0} ]
	then
		writeToLog "\n[$(date -Is)] Backups rotation begins"

		true $((i = i - 1))

		# Remove the oldest backup if exists
		bak="bak$i"
		rm -rf ${!bak}

		# Rotate the previous backups
		while [ $i -gt 0 ]
		do
			bakNewPath="bak$i"
			true $((i = i - 1))
			bakOldPath="bak$i"
			if [ -d ${!bakOldPath} ]
			then
				mv ${!bakOldPath} ${!bakNewPath}
			fi
		done

		writeToLog "[$(date -Is)] Backups rotation finished\n"
	else
		writeToLog "\n[$(date -Is)] No previous data found, there is no backups to be rotated\n"
	fi
else
	writeToLog "\n[$(date -Is)] Last backup failed, backups will not be rotated\n"
fi

# Set rotation lock file to detect in next run when backup fails
touch ${rotationLockFilePath}

writeToLog "[$(date -Is)] Backup begins\n"

# Do the backup
rsync ${rsyncFlags} ${src}/ ${bak0}/

# Check rsync success
if [ "$?" -eq "0" ]
then
	writeToLog "\n[$(date -Is)] Backup completed successfully\n"

	# Clear unneeded partials and lock file
	rm -rf ${partialFolderPath} ${rotationLockFilePath}
	rsyncFail=0
else
	writeToLog "\n[$(date -Is)] Backup failed, try again later\n"
	rsyncFail=1
fi

# Send the complete log file to destination
mv ${logFile} ${logPath}

exit ${rsyncFail}
