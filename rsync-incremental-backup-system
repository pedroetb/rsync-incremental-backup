#!/bin/bash

# v1.2.4

# Configuration variables (change as you wish)
src="/"
dst="${1:-/mnt/path/to/target}"
backupDepth=${backupDepth:-7}
timeout=${timeout:-1800}
pathBak0="${pathBak0:-data}"
rotationLockFileName="${rotationLockFileName:-.rsync-rotation-lock}"
pathBakN="${pathBakN:-backup}"
nameBakN="${nameBakN:-backup}"
exclusionFileName="${exclusionFileName:-exclude.txt}"
logDateCmd="${logDateCmd:-printf %(%FT%T%z)T}"
logName="${logName:-rsync-incremental-backup_$(printf '%(%F)T')_$(printf '%(%H-%M-%S)T').log}"
ownFolderName="${ownFolderName:-.rsync-incremental-backup}"
logFolderName="${logFolderName:-log}"
additionalFlags="${additionalFlags:-}"
maxLogFiles="${maxLogFiles:-20}"

# Combinate previously defined variables for use (don't touch this)
ownFolderPath="${HOME}/${ownFolderName}"
tempLogPath="${ownFolderPath}/system_${dst//[\/]/\\}"
exclusionFilePath="${ownFolderPath}/${exclusionFileName}"
bak0="${dst}/${pathBak0}"
rotationLockFilePath="${dst}/${rotationLockFileName}"
logPath="${dst}/${pathBakN}/${logFolderName}"
logFile="${tempLogPath}/${logName}"

# Prepare own folder
mkdir -p "${tempLogPath}"
touch "${logFile}"
touch "${exclusionFilePath}"

writeToLog() {
	echo -e "${1}" | tee -a "${logFile}"
}

writeToLog "********************************"
writeToLog "*                              *"
writeToLog "*   rsync-incremental-backup   *"
writeToLog "*                              *"
writeToLog "********************************"

# Prepare backup paths
i=1
while [ "${i}" -le "${backupDepth}" ]
do
	export "bak${i}=${dst}/${pathBakN}/${nameBakN}.${i}"
	true "$((i = i + 1))"
done

writeToLog "\\n[$(${logDateCmd})] You are going to backup"
writeToLog "\\tfrom:  ${src}"
writeToLog "\\tto:    ${bak0}"
writeToLog "\\twith:"
writeToLog "\\t\\tbackupDepth = ${backupDepth}"
writeToLog "\\t\\tmaxLogFiles = ${maxLogFiles}"
writeToLog "\\t\\tadditionalFlags = ${additionalFlags}"

# Prepare paths at destination
mkdir -p "${dst}" "${logPath}"

if [ ${maxLogFiles} -ne 0 ]
then
	writeToLog "\\n[$(${logDateCmd})] Old logs sending begins\\n"

	# Send old pending logs to destination
	rsync -rhv --remove-source-files --exclude="${logName}" --log-file="${logFile}" \
		"${tempLogPath}/" "${logPath}/"

	writeToLog "\\n[$(${logDateCmd})] Old logs sending finished"
else
	writeToLog "\\n[$(${logDateCmd})] Logs sending disabled, deleting old local logs"

	# Remove all logs except current one
	ls -r ${tempLogPath}/*.log | tail -n +2 | xargs -r rm
fi

writeToLog "\\n[$(${logDateCmd})] Deleting excess of logs at target"

# Try to delete excess of log files, older first
[ -d ${logPath} ] && ls -r ${logPath}/*.log | tail -n +${maxLogFiles} | xargs -r rm

# Rotate backups if last rsync succeeded ..
if [ ! -e "${rotationLockFilePath}" ]
then
	# .. and there is previous data
	if [ -d "${bak0}" ]
	then
		writeToLog "\\n[$(${logDateCmd})] Backups rotation begins"

		true "$((i = i - 1))"

		# Remove the oldest backup if exists
		bak="bak${i}"
		rm -rf "${!bak}"

		# Rotate the previous backups
		while [ "${i}" -gt 0 ]
		do
			bakNewPath="bak${i}"
			true "$((i = i - 1))"
			bakOldPath="bak${i}"
			if [ -d "${!bakOldPath}" ]
			then
				mv "${!bakOldPath}" "${!bakNewPath}"
			fi
		done

		writeToLog "[$(${logDateCmd})] Backups rotation finished\\n"
	else
		writeToLog "\\n[$(${logDateCmd})] No previous data found, there is no backups to be rotated\\n"
	fi
else
	writeToLog "\\n[$(${logDateCmd})] Last backup failed, backups will not be rotated\\n"
fi

# Set rotation lock file to detect in next run when backup fails
touch "${rotationLockFilePath}"

writeToLog "[$(${logDateCmd})] Backup begins\\n"

# Do the backup (with mandatory exclusions)
rsync -aAhv --progress --timeout="${timeout}" --delete -W --link-dest="${bak1}/" \
	--log-file="${logFile}" --exclude="${ownFolderName}/" --exclude-from="${exclusionFilePath}" \
	--exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
	${additionalFlags} "${src}/" "${bak0}/"

rsyncExitCode=${?}
if [ ${rsyncExitCode} -eq 0 ] || [ ${rsyncExitCode} -eq 24 ]
then
	writeToLog "\\n[$(${logDateCmd})] Backup completed successfully"

	# Clear unneeded partials and lock file
	rm -rf "${rotationLockFilePath}"
	# Update backup directory modification time
	touch -m "${bak0}"
	rsyncFail=0
else
	writeToLog "\\n[$(${logDateCmd})] Backup failed, try again later"
	rsyncFail=1
fi

if [ ${maxLogFiles} -ne 0 ]
then
	writeToLog "\\n[$(${logDateCmd})] Sending current log to target"

	# Send the complete log file to destination
	mv "${logFile}" "${logPath}"
fi

exit "${rsyncFail}"
