# rsync-incremental-backup

Configurable bash scripts to send incremental backups of your data to a local or remote target, using [rsync](https://download.samba.org/pub/rsync/rsync.html).


## Description

These scripts does (as many as you want) incremental backups of the desired directory to another local or remote directory. The first directory acts as a master (doesn't get modified), making copies of itself at the second directory (slave). Then, you can browse the slave directory and get any file included into any previous backup.

Only new or modified data is stored (because it's incremental), so the size of backups doesn't grow too much.

If a backup process gets interrupted, don't worry. You can continue it in the next run of the script without data lose and without transferring previously transferred data.


## Configuration

You can set some configuration variables to customize the script:

* `src`: Path to source directory. Backups will include it's content.
* `dst`: Path to target directory. Backups will be placed here.
* `backupDepth`: Number of backups to keep. When limit is reached, the oldest get deleted.
* `timeout`: Timeout to cancel backup process, if it's not responding.
* `remoteUser`: User to connect to remote host (only for remote version).
* `remoteHost`: Address of remote host (only for remote version).
* `pathBak0`: Directory inside `dst` where the more recent backup is stored.
* `partialFolderName`: Directory inside `dst` where partial files are stored.
* `pathBakN`: Directory inside `dst` where the rest of backups are stored.
* `nameBakN`: Name of incremental backup directories. An index will be added at the end to show how old they are.
* `logName`: Name given to log file generated at backup.
* `tempLogPath`: Path where the log file will be stored while backup is in progress.
* `logFolderName`: Directory inside `dst` where the log files are stored.


## Usage

Once configured with your own values, you can simply run the script to begin the backup process.

Personally, I schedule it to run every week with [anacron](https://en.wikipedia.org/wiki/Anacron). This way, I don't need to remember running it.

If you are using the default folder names, the newest data backup will be inside `<dst>/data`. The second newest backup will be inside `<dst>/backup/backup.1`, next will be inside `<dst>/backup/backup.2` and so on.


## Used rsync flags explanation

* `-a`: archive mode; equals -rlptgoD (no -H,-A,-X). Mandatory for backup usage.
* `-c`: skip based on checksum, not mod-time & size. More trustworthy, but slower. Omit this flag if you want faster backups, but files without changes in modified time or size won't be detected for include in backup.
* `-h`: output numbers in a human-readable format.
* `-v`: increase verbosity for logging.
* `-z`: compress file data during the transfer. Less data transmitted, but slower. Omit this flag when backup target is a local device or a machine in local network (or when you have a high bandwidth to a remote machine).
* `--progress`: show progress per file during transfer. Only for interactive usage.
* `--info=progress2`: show progress based on the whole transfer, rather than individual files. Only for interactive usage.
* `--timeout`: set I/O timeout in seconds. If no data is transferred for the specified time, backup will be aborted.
* `--delete`: delete extraneous files from dest dirs. Mandatory for master-slave backup usage.
* `--no-W`: ensures that rsync's delta-transfer algorithm is used, so it never transfers whole files if they are present at target. Omit only when you have a high bandwidth to target, backup may be faster.
* `--partial-dir`: put a partially transferred file into specified directory, instead of using a hidden file in the original path of transferred file. Mandatory for allow partial transfers and avoid misleads with incomplete/corrupt files.
* `--link-dest`: hardlink to files in specified directory when unchanged, to reduce storage usage by duplicated files between backups.
* `--log-file`: log what we're doing to the specified file.


## References

I was inspired by [Incremental Backups on Linux](http://www.admin-magazine.com/Articles/Using-rsync-for-Backups) to make this script.
