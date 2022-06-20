#!/bin/bash

# v1.2.4

# Configuration variables (change as you wish)
src="/"
dst="${1:-/path/to/target}"
remote="${2:-ssh_remote}"
backupDepth=${backupDepth:-7}
timeout=${timeout:-1800}
pathBak0="${pathBak0:-data}"
partialFolderName="${partialFolderName:-.rsync-partial}"
rotationLockFileName="${rotationLockFileName:-.rsync-rotation-lock}"
pathBakN="${pathBakN:-backup}"
nameBakN="${nameBakN:-backup}"
exclusionFileName="${exclusionFileName:-exclude.txt}"
logDateCmd="${logDateCmd:-printf %(%FT%T%z)T}"
logName="${logName:-rsync-incremental-backup_$(printf '%(%F)T')_$(printf '%(%H-%M-%S)T').log}"
ownFolderName="${ownFolderName:-.rsync-incremental-backup}"
logFolderName="${logFolderName:-log}"
interactiveMode="${interactiveMode:-no}"
additionalFlags="${additionalFlags:-}"
maxLogFiles="${maxLogFiles:-20}"
useCompression="${useCompression:-1}"

# Combinate previously defined variables for use (don't touch this)
ownFolderPath="${HOME}/${ownFolderName}"
tempLogPath="${ownFolderPath}/${remote}_${dst//[\/]/\\}"
exclusionFilePath="${ownFolderPath}/${exclusionFileName}"
remoteDst="${remote}:${dst}"
bak0="${dst}/${pathBak0}"
remoteBak0="${remoteDst}/${pathBak0}"
partialFolderPath="${dst}/${partialFolderName}"
rotationLockFilePath="${dst}/${rotationLockFileName}"
logPath="${dst}/${pathBakN}/${logFolderName}"
remoteLogPath="${remote}:${logPath}"
logFile="${tempLogPath}/${logName}"

if [ ${useCompression} -eq 0 ]
then
	compressionFlag=""
else
	compressionFlag="z"
fi

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
writeToLog "\\tto:    ${remoteBak0}"
writeToLog "\\twith:"
writeToLog "\\t\\tbackupDepth = ${backupDepth}"
writeToLog "\\t\\tmaxLogFiles = ${maxLogFiles}"
writeToLog "\\t\\tuseCompression = ${useCompression}"
writeToLog "\\t\\tadditionalFlags = ${additionalFlags}"
writeToLog "\\t\\tinteractiveMode = ${interactiveMode}"

# Prepare ssh parameters for socket connection, reused by following sessions
sshParams=(-o "ControlPath=\"${ownFolderPath}/ssh_connection_socket_%h_%p_%r\"" -o "ControlMaster=auto" \
	-o "ControlPersist=10")

# Prepare rsync transport shell with ssh parameters (escape for proper space handling)
rsyncShellParams=(-e "ssh$(for i in "${sshParams[@]}"; do echo -n " '${i}'"; done)")

batchMode="yes"
if [ "${interactiveMode}" = "yes" ]
then
	batchMode="no"
fi

# Check remote connection and create master socket connection
if ! ssh "${sshParams[@]}" -q -o BatchMode="${batchMode}" -o ConnectTimeout=10 "${remote}" exit
then
	writeToLog "\\n[$(${logDateCmd})] Remote destination is not reachable"
	exit 1
fi

# Prepare paths at destination
ssh "${sshParams[@]}" "${remote}" "mkdir -p ${dst} ${logPath}"

if [ ${maxLogFiles} -ne 0 ]
then
	writeToLog "\\n[$(${logDateCmd})] Old logs sending begins\\n"

	# Send old pending logs to destination
	rsync "${rsyncShellParams[@]}" -rhv${compressionFlag} --remove-source-files --exclude="${logName}" \
		--log-file="${logFile}" "${tempLogPath}/" "${remoteLogPath}/"

	writeToLog "\\n[$(${logDateCmd})] Old logs sending finished"
else
	writeToLog "\\n[$(${logDateCmd})] Logs sending disabled, deleting old local logs"

	# Remove all logs except current one
	ls -r ${tempLogPath}/*.log | tail -n +2 | xargs -r rm
fi

writeToLog "\\n[$(${logDateCmd})] Deleting excess of logs at target"

# Try to delete excess of log files, older first
ssh "${sshParams[@]}" "${remote}" "[ -d ${logPath} ] && ls -r ${logPath}/*.log | tail -n +${maxLogFiles} | xargs -r rm"

# Rotate backups if last rsync succeeded ..
if (ssh "${sshParams[@]}" "${remote}" "[ ! -d ${partialFolderPath} ] && [ ! -e ${rotationLockFilePath} ]")
then
	# .. and there is previous data
	if (ssh "${sshParams[@]}" "${remote}" "[ -d ${bak0} ]")
	then
		writeToLog "\\n[$(${logDateCmd})] Backups rotation begins"

		true "$((i = i - 1))"

		# Remove the oldest backup if exists
		bak="bak${i}"
		ssh "${sshParams[@]}" "${remote}" "rm -rf ${!bak}"

		# Rotate the previous backups
		while [ "${i}" -gt 0 ]
		do
			bakNewPath="bak${i}"
			true "$((i = i - 1))"
			bakOldPath="bak${i}"
			if (ssh "${sshParams[@]}" "${remote}" "[ -d ${!bakOldPath} ]")
			then
				ssh "${sshParams[@]}" "${remote}" "mv ${!bakOldPath} ${!bakNewPath}"
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
ssh "${sshParams[@]}" "${remote}" "touch ${rotationLockFilePath}"

writeToLog "[$(${logDateCmd})] Backup begins\\n"

# Do the backup
rsync "${rsyncShellParams[@]}" -aAhv${compressionFlag} --numeric-ids -M--fake-super --progress --timeout="${timeout}" \
	--delete --no-W --partial-dir="${partialFolderName}" --link-dest="${bak1}/" --log-file="${logFile}" \
	--exclude="${ownFolderName}/" \
	--exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
	--exclude-from="${exclusionFilePath}" ${additionalFlags} \
	"${src}/" "${remoteBak0}/"

rsyncExitCode=${?}
if [ ${rsyncExitCode} -eq 0 ] || [ ${rsyncExitCode} -eq 24 ]
then
	writeToLog "\\n[$(${logDateCmd})] Backup completed successfully"

	# Clear unneeded partials and lock file
	ssh "${sshParams[@]}" "${remote}" "rm -rf ${partialFolderPath} ${rotationLockFilePath}"
	# Update backup directory modification time
	ssh "${sshParams[@]}" "${remote}" "touch -m ${bak0}"
	rsyncFail=0
else
	writeToLog "\\n[$(${logDateCmd})] Backup failed, try again later"
	rsyncFail=1
fi

if [ ${maxLogFiles} -ne 0 ]
then
	writeToLog "\\n[$(${logDateCmd})] Sending current log to target"

	# Send the complete log file to destination
	if scp "${sshParams[@]}" "${logFile}" "${remoteLogPath}"
	then
		rm "${logFile}"
	fi
fi

# Close master socket connection quietly
ssh "${sshParams[@]}" -q -O exit "${remote}"

exit "${rsyncFail}"
