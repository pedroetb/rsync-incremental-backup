#!/bin/bash

# V3.2

# ==> Variables
# media="/media/juanb/xdata"
# media="/media/juanb/xvms/backup/rdiffbackup/"
# mountpoint="/media/$USER/xvms"
# targetdir="$mountpoint/backup/rdiffbackup/"
#
# sourcedir[0]="/data/Dropbox"
# sourcedir[1]="/data/GoogleDrive"
# sourcedir[2]="/data/ownCloud"
# sourcedir[3]="/data/SpiderOak Hive"
# sourcedir[4]="$USER/SpiderOak Hive"

mountpoint="/media/$USER/SeagateBackupPl"
mountdir="$mountpoint/testbackup/rdiffbackup"

sourcedir[0]="/data/Dropbox"
targetdir[0]="data_Dropbox"
sourcedir[1]="/data/GoogleDrive"
targetdir[1]="data_GoogleDrive"
sourcedir[2]="/data/SpiderOak Hive"
targetdir[2]="data_SpiderOak_Hive"
sourcedir[3]="$USER/SpiderOak Hive"
targetdir[3]="kubuntu_SpiderOak_Hive"
sourcedir[4]="/data/.thunderbird"
targetdir[4]="_thunderbird"
sourcedir[5]="/etc"
targetdir[5]="kubuntu_etc"
# sourcedir[6]="/data/ownCloud"
# targetdir[6]="data_ownCloud"
noOfDirs=${#sourcedir[@]}


#--------------------------------------------------------------------------------------------------
# ############################################################################
# ==> set debugging on
# echo "Press CTRL+C to proceed."
# trap "pkill -f 'sleep 1h'" INT
# trap "set +xv ; sleep 1h ; set -xv" DEBUG
# set -e  # Fail on first error
# trap 'exit $?' ERR
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# ############################################################################
# ==> set debugging on and create debugging log files debug.log and error.log
INTERACTIVE_MODE="on"
scriptDebugToStdout=0
scriptDebugToFile=1
if [[ $scriptDebugToFile == 1 ]]; then
  cat /dev/null > debug.log
  cat /dev/null > error.log
  # if [[ -e debug.log ]]; then
    # >debug.log
  # else
    # touch debug.log
  # fi
  # if [[ -e error.log ]]; then
    # >error.log
  # else
    # touch error.log
  # fi
fi

# ############################################################################
# log4bash
#--------------------------------------------------------------------------------------------------
# Begin Logging Section
if [[ "${INTERACTIVE_MODE}" == "off" ]]
then
    # Then we don't care about log colors
    declare -r LOG_DEFAULT_COLOR=""
    declare -r LOG_ERROR_COLOR=""
    declare -r LOG_INFO_COLOR=""
    declare -r LOG_SUCCESS_COLOR=""
    declare -r LOG_WARN_COLOR=""
    declare -r LOG_DEBUG_COLOR=""
else
    declare -r LOG_DEFAULT_COLOR="\033[0m"
    declare -r LOG_ERROR_COLOR="\033[1;31m"
    declare -r LOG_INFO_COLOR="\033[1m"
    declare -r LOG_SUCCESS_COLOR="\033[1;32m"
    declare -r LOG_WARN_COLOR="\033[1;33m"
    declare -r LOG_DEBUG_COLOR="\033[1;34m"
fi

log() {
    local log_text="$1"
    local log_level="$2"
    local log_color="$3"

    # Default level to "info"
    [[ -z ${log_level} ]] && log_level="INFO";
    [[ -z ${log_color} ]] && log_color="${LOG_INFO_COLOR}";

    if [[ $scriptDebugToStdout == 1 ]]; then
      echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}";
    fi
    if [[ $scriptDebugToFile == 1 ]]
    then
      echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}" >>debug.log 2>>error.log
    fi
    # [[ $script_debug = 1 ]] && echo -e "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}" >>debug.log 2>>error.log || :
    return 0;
}

log_info()      { log "$@"; }
log_success()   { log "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
log_error()     { log "$1" "ERROR" "${LOG_ERROR_COLOR}"; }
log_warning()   { log "$1" "WARNING" "${LOG_WARN_COLOR}"; }
log_debug()     { log "$1" "DEBUG" "${LOG_DEBUG_COLOR}"; }
# ############################################################################
# Print the newest file, if any, matching the given pattern
# Example usage:
#   newest_matching_file 'b2*'
# WARNING: Files whose names begin with a dot will not be checked
function newest_matching_file
{
    # Use ${1-} instead of $1 in case 'nounset' is set
    local -r glob_pattern=${1-}

    if (( $# != 1 )) ; then
        echo 'usage: newest_matching_file GLOB_PATTERN' >&2
        return 1
    fi

    # To avoid printing garbage if no files match the pattern, set
    # 'nullglob' if necessary
    local -i need_to_unset_nullglob=0
    if [[ ":$BASHOPTS:" != *:nullglob:* ]] ; then
        shopt -s nullglob
        need_to_unset_nullglob=1
    fi

    newest_file=
    for file in $glob_pattern ; do
        [[ -z $newest_file || $file -nt $newest_file ]] \
            && newest_file=$file
    done

    # To avoid unexpected behaviour elsewhere, unset nullglob if it was
    # set by this function
    (( need_to_unset_nullglob )) && shopt -u nullglob

    # Use printf instead of echo in case the file name begins with '-'
    [[ -n $newest_file ]] && printf '%s\n' "$newest_file"

    return 0
}
# ############################################################################
#--------------------------------------------------------------------------------------------------
# ###################################################################3########


# ############################################################################
#--------------------------------------------------------------------------------------------------


# ############################################################################
# Die process to exit because of a failure
die() { echo "$*" >&2; exit 1; }

# ============================================================================================
# Backup Function
backupfunc () {
  printf "\n"
  printf "Start of rdiff-backup\n"
  printf "Number of sourcedirs = %s\n" "$noOfDirs"

  if [ "$(/bin/mount | /bin/grep -c "$mountpoint")" -gt 0 ]
  then
  	for (( i = 0; i < "$noOfDirs"; i++ )); do
  	  printf "\n"
  		printf "##################### %s #####################################################\n" "${sourcedir[i]}"
      # log_debug "dest = ${destdir[i]}"

  		printf "Backup Directory Mounted, busy doing a backup of %s to %s\n" "${sourcedir[i]}" "${destdir[i]}" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
          #  /usr/bin/rdiff-backup -v5 --terminal-verbosity 3 --exclude=**/*tmp*/ --exclude=**/*cache*/ --exclude=**/*Cache*/ --exclude=**~ --exclude=**/lost+found*/ --exclude=**/*Trash*/ --exclude=**/*trash*/ --exclude=**/.gvfs/ "${sourcedir[i]}" "${destdir[i]}" 2>&1 | awk '// { print strftime("[%H:%M:%S] ") $0; }'
           /usr/bin/rdiff-backup -v5 --terminal-verbosity 3   \
           --exclude ignorecase:'**/*tmp*/'                   \
           --exclude ignorecase:'**/*cache*/'                 \
           --exclude '**~'                                    \
           --exclude '**/lost+found*/'                        \
           --exclude ignorecase:'**/*trash*/'                 \
           --exclude '**/.gvfs/'                              \
           --exclude-symbolic-links                           \
           "${sourcedir[i]}" "${destdir[i]}" 2>&1 | awk '// { print strftime("[%H:%M:%S] ") $0; }'
      printf "Backup of %s to %s completed.\n" "${sourcedir[i]}" "${destdir[i]}" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
      printf "\n"
      backuplogfile=$(newest_matching_file "${destdir[i]}/rdiff-backup-data/session*.data")
      cat "$backuplogfile"
      printf "#############################################################################\n"
  	done
  else
     printf "Backup filesystem %s not mounted !!! Cowardly refusing your backup !\n" "$mountpoint" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
     exit 1
  fi
  return 0
}

# ============================================================================================
# Clean Backups function
backupclean () {
  printf "\nStart of Clean Backups"
  printf "\nNumber of backup dirs = %s\n" "$noOfDirs"

  # log_debug "cleantime = $1"
  if [[ "$(/bin/mount | /bin/grep -c "$mountpoint")" = '1' ]]
  then
  	for (( i = 0; i < "$noOfDirs"; i++ )); do
  		printf "\n"
  		printf "##################### %s #####################################################\n" "${sourcedir[i]}"

  		printf "Backup Directory Mounted, start removing backups older than %s at %s" "$1" "${destdir[i]}" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
       /usr/bin/rdiff-backup --force --remove-older-than "$1" "${destdir[i]}" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
  		printf "#############################################################################\n"
  	done
  else
     printf "Backup filesystem %s not mounted !!! Can't clean your backups !\n" "$mountpoint" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
     exit 1
  fi
  return 0
}

# ============================================================================================
# Backup sizes function
backupsizes () {
  printf "\nStart of scanning Backup sizes"
  printf "\nNumber of backup dirs = %s\n" "$noOfDirs"

  if [ "$(/bin/mount | /bin/grep -c "$mountpoint")" = '1' ]
  then
  	for (( i = 0; i < "$noOfDirs"; i++ )); do
  		printf "\n"
  		printf "##################### %s #####################################################\n" "${sourcedir[i]}"

  		printf "Backup Directory Mounted, will scan backup size of %s \n" "${destdir[i]}" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
      /usr/bin/rdiff-backup --list-increment-sizes "${destdir[i]}" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
  		printf "#############################################################################\n"
  	done
  else
     printf "Backup filesystem %s not mounted !!! Can't scan your backup sizes !\n" "$mountpoint" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
     exit 1
  fi
  return 0
}

# ############################################################################################
# ############################################################################################
# ============================================================================================
# Here is where the main script starts
# Above were the functions to be used
clear

if [ "$(upower -i "$(upower -e | grep ACAD)" | grep --color=never -E online|xargs|cut -d' ' -f2|sed s/%//)" = 'no' ]
then
   printf "We are running on battery, refusing the backup commands to save Power!!!" | awk '// { print strftime("[%H:%M:%S] ") $0; }'
   exit 1
fi


#Read and interpret input parameters
# log_debug "parameters = $@"
if [[ ! -z $1 ]]; then
  while [ ! -z "$1" ]; do
    case $1 in
      -f | --file )
        shift
        inputFile=$1 #Don't think I need this
        # log_info "inputFile = $inputFile"
        declare -a backupFile #declare an array to contain the file contents, can probably do this straight to the variables as well
        count=0 ## read the file lines into the array
        while IFS='' read -r line || [[ -n $line ]]; do
          # log_debug "This is what is coming from the file: $line"
          if [[ -n "$line" && "$line" != [[:blank:]#]* ]]; then
            # log_warning "This is what was filtered: $line"
            backupFile[$count]=$line
            # log_debug "This is what is placed in backupFile $count = ${backupFile[count]}"
            ((count+=1))
          fi
        done < "$inputFile"

        # replace the default values with the file values
        mountpoint=${backupFile[0]}
        mountdir="$mountpoint${backupFile[1]}"
        # ${sourcedir[@]+"${sourcedir[@]}"}
        # ${targetdir[@]+"${targetdir[@]}"}
        unset sourcedir
        unset targetdir
        #loop the directories list into the sourcedir and targetdir array
        for ((a = 0; a < "$count-2"; a++)) do
          if [[ ${backupFile[a+2]} == *"@"* ]]; then
            # log_debug "before the @ = ${backupFile[a+2]%@*}"
            sourcedir[a]=${backupFile[a+2]%@*}
            # log_debug "after te @ = ${backupFile[a+2]#*@}"
            targetdir[a]=${backupFile[a+2]#*@}
            # Alternative to the scripts above
            # sourcedir[a]=$(echo ${backupFile[a+2]} | cut -f1 -d@)
            # targetdir[a]=$(echo ${backupFile[a+2]} | cut -f2 -d@)
          else
            sourcedir[a]=${backupFile[a+2]}
          fi
        done
        noOfDirs=${#sourcedir[@]}
      ;;
      -h | --help )
        echo "usage: -[[-f file ] backup file name] (the file has a specific format please check the sample file)"
        exit 0
      ;;
      * )
        echo "usage: -[[-f file ] backup file name] (the file has a specific format please check the sample file)"
        exit 0
      ;;
    esac
    shift
  done #donewhile $1 File paramentrs

fi # endif file parameters

# log_info "\n"
# loop the directories list into the sourcedir array
# log_info "mountpoint = $mountpoint"
# log_info "mountdir = $mountdir"
noOfDirs=${#sourcedir[@]}
# log_info "Number of directories = $noOfDirs"
# log_info "\n"

for ((a = 0; a < "$noOfDirs"; a++)) do
  # log_debug "sourcedir $a = ${sourcedir[a]}"
  # log_debug "targetdir $a = ${targetdir[a]}"
  if [[ -z "${targetdir[a]// }" ]]; then
    # log_error "targetdir $a is empty"
    # log_warning "targetdir [$a] = ${sourcedir[a]:1}"
    targetdir[a]=${sourcedir[a]:1}
    # log_warning "targetdir $a = ${targetdir[a]}"
  fi
  targetdir[a]=${targetdir[a]//[^A-Za-z0-9]/_}
  targetdir[a]=${targetdir[a]//___/_}
  targetdir[a]=${targetdir[a]//__/_}

  destdir[a]=$mountdir"/"${targetdir[a]}

  # log_info "List of backup dirs..."
  # log_debug "sourcedir $a = ${sourcedir[a]}"
  # log_debug "targetdir $a = ${targetdir[a]}"
  # log_debug "destdir $a = ${destdir[a]}"
  # log_info "Done with backup set.\n"
done

## busy now
# test the read from the file above
## end busy now
## next step
## end of next step



##### Main menu section
until [[ "$choice" = "q" ]]; do
  printf "
  MESSAGE : In case of options, one value is displayed as the default value.
  Do erase it to use other value.

  myBackup v0.1

  This script is documented in README.md file.

  There are the following options for this script
  TASK   :     DESCRIPTION

  b : Backup the system
  s : Show the sizes of the backups
  c : Clean the backup according to a time request

  q       : Quit this program

  "

  read -rp "Enter your choice : " choice
  # printf "%s" "$choice"
  # printf "Enter your system password if asked...\n"

  # take inputs and perform as necessary
  case "$choice" in
  	b)
  		# printf "%s" choice
      backupfunc
  		echo "All Backup Operations completed successfully."
  		;;
  	s)
  		# printf "%s" "$choice"
      backupsizes
  		;;
  	c)	printf "\n"
  			printf "What time unit do you want to use? Options are:\n"
        printf "time string, which can be given in any of several formats:

       1.     the string \"now\" (refers to the current time)

       2.     a sequences of digits, like \"123456890\" (indicating the time  in seconds after the epoch)

       3.     A string like \"2002-01-25T07:00:00+02:00\" in datetime format

       4.     An interval, which is a number followed by one of the characters s, m, h, D, W, M, or  Y  (indicating  seconds,  minutes,  hours, days, weeks, months, or years respectively), or a series of such pairs.  In this case the string refers to the time that preceded the  current  time by the length of the interval.  For instance, \"1h78m\" indicates the time that was one hour and 78 minutes ago. The calendar here is unsophisticated: a month is always 30 days, a year is always 365 days, and a day is always 86400 seconds.

       5.     A date format of the form YYYY/MM/DD, YYYY-MM-DD, MM/DD/YYYY, or MM-DD-YYYY,  which  indicates  midnight  on the day in question, relative  to  the  current  timezone  settings.   For  instance, \"2002/3/5\",  \"03-05-2002\",  and  \"2002-3-05\" all mean March 5th, 2002.

       6.     A backup session specification which is a  non-negative  integer followed  by  'B'.  For instance, '0B' specifies the time of the current mirror, and '3B' specifies the time of  the  3rd  newest increment.
         "

        read -rp "Type the string that you want to use for the clean opperation:  " cleantime
        backupclean "$cleantime"
        printf "All %s older backups were cleanded." "$cleantime"
  			;;
  	q)	;;
  	*) exit 1
  		;;
  esac  #statements
done
printf "\n"
printf "Job done!\n"
printf "Thanks for using myBackup. :-)\n"
# ############################################################################
# set debugging off
  # set -xv
exit 0
