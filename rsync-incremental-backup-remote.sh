#!/bin/bash

# Configuration variables (change as you wish)
src="/path/to/source"
dst="/path/to/target"
remote="ssh_remote"
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
tempLogPath="${tempLogBasePath}/${remote}_${dst//[\/]/\\}"
remoteDst="${remote}:${dst}"
bak0="${dst}/${pathBak0}"
remoteBak0="${remoteDst}/${pathBak0}"
partialFolderPath="${dst}/${partialFolderName}"
rotationLockFilePath="${dst}/${rotationLockFileName}"
logPath="${dst}/${pathBakN}/${logFolderName}"
remoteLogPath="${remote}:${logPath}"
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
rsyncFlags="-achvz --info=progress2 --timeout=${timeout} --delete --no-W --partial-dir=${partialFolderName} \
--link-dest=${bak1}/ --log-file=${logFile} --exclude=${tempLogBasePath} --chmod=+r"

# Prepare log rsync configuration
logRsyncFlags="-rhvz --remove-source-files --exclude=${logName} --log-file=${logFile}"

writeToLog "\n[$(date -Is)] You are going to backup"
writeToLog "\tfrom:  ${src}"
writeToLog "\tto:    ${remoteBak0}"
writeToLog "\tflags: ${rsyncFlags}"

# Check remote connection
ssh -q -o BatchMode=yes -o ConnectTimeout=10 ${remote} exit
if [ "$?" -ne "0" ]
then
	writeToLog "\n[$(date -Is)] Remote destination is not reachable"
	exit 1
fi

# Prepare paths at destination
ssh ${remote} "mkdir -p ${dst} ${logPath}"

writeToLog "\n[$(date -Is)] Old logs sending begins\n"

# Send old pending logs to destination
# echo -en "rsync ${logRsyncFlags} ${tempLogPath}/ ${remoteLogPath}/\n\n"
rsync ${logRsyncFlags} ${tempLogPath}/ ${remoteLogPath}/

writeToLog "\n[$(date -Is)] Old logs sending finished"

# Rotate backups if last rsync succeeded ..
if (ssh ${remote} "[ ! -d ${partialFolderPath} ] && [ ! -e ${rotationLockFilePath} ]")
then
	# .. and there is previous data
	if (ssh ${remote} "[ -d ${bak0} ]")
	then
		writeToLog "\n[$(date -Is)] Backups rotation begins"

		true $((i = i - 1))

		# Remove the oldest backup if exists
		bak="bak$i"
		ssh ${remote} "rm -rf ${!bak}"

		# Rotate the previous backups
		while [ $i -gt 0 ]
		do
			bakNewPath="bak$i"
			true $((i = i - 1))
			bakOldPath="bak$i"
			if (ssh ${remote} "[ -d ${!bakOldPath} ]")
			then
				ssh ${remote} "mv ${!bakOldPath} ${!bakNewPath}"
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
ssh ${remote} "touch ${rotationLockFilePath}"

writeToLog "[$(date -Is)] Backup begins\n"

# Do the backup
echo -en "rsync ${rsyncFlags} ${src}/ ${remoteBak0}/\n\n"
rsync ${rsyncFlags} ${src}/ ${remoteBak0}/

# Check rsync success
if [ "$?" -eq "0" ]
then
	writeToLog "\n[$(date -Is)] Backup completed successfully\n"

	# Clear unneeded partials and lock file
	ssh ${remote} "rm -rf ${partialFolderPath} ${rotationLockFilePath}"
	rsyncFail=0
else
	writeToLog "\n[$(date -Is)] Backup failed, try again later\n"
	rsyncFail=1
fi

# Send the complete log file to destination
scp ${logFile} ${remoteLogPath}
if [ "$?" -eq "0" ]
then
	rm ${logFile}
fi

exit ${rsyncFail}
