# rsync-incremental-backup

Configurable bash scripts to send incremental backups of your data to a local or remote target, using [rsync](https://download.samba.org/pub/rsync/rsync.html).


## Description

These scripts do (as many as you want) incremental backups of desired directory to another local or remote directory.
The first directory acts as master (doesn't get modified), making copies of itself at the second directory (slave).
Then, you can browse the slave directory and get any file included into any previous backup.

Only new or modified data is stored (because it's incremental), so the size of backups doesn't grow too much.

If a backup process gets interrupted, don't worry. You can continue it in the next run of the script without data loss and without resending previously transferred data.

In addition, there is a local backup script with special configuration, oriented to do backups for a GNU/Linux filesystem.
For example, it already has omitted temporal, removable and other problematic paths, and is meant to backup to a external mount point (at `/mnt`).


## Configuration

You can set some configuration variables to customize the script:

* `src`: Path to source directory. Backups will include it's content. May be a relative or absolute path. Overwritable by parameters.
* `dst`: Path to target directory. Backups will be placed here. **Must** be an absolute path. Overwritable by parameters.
* `remote`: *ssh_config* host name to connect to remote host (only for remote version). Overwritable by parameters.
* `backupDepth`: Number of backups to keep. When limit is reached, the oldest get deleted.
* `timeout`: Timeout to cancel backup process, if it's not responding.
* `pathBak0`: Directory inside `dst` where the more recent backup is stored.
* `partialFolderName`: Directory inside `dst` where partial files are stored.
* `rotationLockFileName`: Name given to rotation lock file, used for detecting previous backup failures.
* `pathBakN`: Directory inside `dst` where the rest of backups are stored.
* `nameBakN`: Name of incremental backup directories. An index will be added at the end to show how old they are.
* `logName`: Name given to log file generated at backup.
* `exclusionFileName`: Name given to the text file that contains exclusion patterns. You must create it inside directory defined by `ownFolderName`.
* `ownFolderName`: Name given to folder inside user's home to hold configuration files and logs while backup is in progress.
* `logFolderName`: Directory inside `dst` where the log files are stored.
* `dateCmd`: Command to run for GNU `date`

All files and folders in backup (local and remote only) get read permissions for all users, since a non-readable backup is useless.
If you are worried about permissions, you can add a security layer on backup access level (FTP accounts protected with passwords, for example).
You can also preserve original files and folders permissions removing the `--chmod=+r` flag from script.
In system backup, the original permissions are preserved by default.


## Usage

### Setting up *ssh_config* (for remote version)

This script is meant to run without user intervention, so you need to authorize your source machine to access the remote machine.
To accomplish this, you should use *ssh keys* to identify you and set a *ssh host* to use them properly.

There are lots of tutorials dedicated to these topics, you can follow one of them.
I won't go into more detailed explanation on this, but here are some good references:

* [How To Set Up SSH Keys](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)
* [OpenSSH Config File Examples](https://www.cyberciti.biz/faq/create-ssh-config-file-on-linux-unix/)

After that, you should use the `Host` value from your *ssh config file* as the `remote` value in the script.

### Customizing configuration values

You have to set, at least, `src` and `dst` (and `remote` in remote version) values, directly in the scripts or by positional parameters when running them:

* `./rsync-incremental-backup-local /new/path/to/source /new/path/to/target` (`src` and `dst`).
* `./rsync-incremental-backup-remote /new/path/to/source /new/path/to/target new_ssh_remote` (`src`, `dst` and `remote`).
* `./rsync-incremental-backup-system /mnt/new/path/to/target` (only `dst`, `src` is always *root* on this case).

If you want to exclude some files or directories from backup, add their paths (relative to backup root) to the text file referenced by `exclusionFileName`.

Once configured with your own variable values, you can simply run the script to begin the backup process.

### Automating backups

Personally, I schedule it to run every week with [anacron](https://en.wikipedia.org/wiki/Anacron) in user mode. This way, I don't need to remember running it.

To use anacron in user mode, you have to follow these steps:

* Create an `.anacron` folder in your home directory with subfolders `etc` and `spool`.

```
mkdir ~/.anacron
mkdir ~/.anacron/etc
mkdir ~/.anacron/spool
```

* Create an `anacrontab` file at `~/.anacron/etc` with this content (or equivalent, be sure to specify the right path to script):

```
# /etc/anacrontab: configuration file for anacron

# See anacron(8) and anacrontab(5) for details.

SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
START_HOURS_RANGE=8-22

# period delay job-identifier command
7 5 weekly_backup ~/bin/rsync-incremental-backup-remote
```

* Make your anacron start at login. Add this content at the end of to your `~/.profile` file:

```
# User anacron
/usr/sbin/anacron -s -t ${HOME}/.anacron/etc/anacrontab -S ${HOME}/.anacron/spool
```

### Checking backup content

If you are using the default folder names, the newest data backup will be inside `<dst>/data`.
The second newest backup will be inside `<dst>/backup/backup.1`, next will be inside `<dst>/backup/backup.2` and so on.
Log files per backup operation will be stored at `<dst>/log`.


## Used *rsync* flags explanation

* `-a`: archive mode; equals -rlptgoD (no -H,-A,-X). Mandatory for backup usage.
* `-c`: skip based on checksum, not mod-time & size. More trustworthy, but slower. Omit this flag if you want faster backups, but files without changes in modified time or size won't be detected for include in backup.
* `-h`: output numbers in a human-readable format.
* `-v`: increase verbosity for logging.
* `-z`: compress file data during the transfer. Less data transmitted, but slower. Omit this flag when backup target is a local device or a machine in local network (or when you have a high bandwidth to a remote machine).
* `--progress`: show progress per file during transfer. Only for interactive usage.
* `--timeout`: set I/O timeout in seconds. If no data is transferred for the specified time, backup will be aborted.
* `--delete`: delete extraneous files from dest dirs. Mandatory for master-slave backup usage.
* `--link-dest`: hardlink to files in specified directory when unchanged, to reduce storage usage by duplicated files between backups.
* `--log-file`: log what we're doing to the specified file.
* `--chmod`: affect file and/or directory permissions.
* `--exclude`: exclude files matching pattern.
* `--exclude-from`: same as `--exclude`, but getting patterns from specified file.

* Used only for remote backup:
	* `--no-W`: ensures that rsync's delta-transfer algorithm is used, so it never transfers whole files if they are present at target. Omit only when you have a high bandwidth to target, backup may be faster.
	* `--partial-dir`: put a partially transferred file into specified directory, instead of using a hidden file in the original path of transferred file. Mandatory for allow partial transfers and avoid misleads with incomplete/corrupt files.

* Used only for local backups:
	* `-W`: ignores rsync's delta-transfer algorithm, so it always transfers whole files. When you have a high bandwidth to target (local filesystem or LAN), backup may be faster.

* Used only for system backup:
	* `-A`: preserve ACLs (implies -p).
	* `-X`: preserve extended attributes.

* Used only for log sending:
	* `-r`: recurse into directories.
	* `--remove-source-files`: sender removes synchronized files (non-dir).



## References

This was inspired by:

* [Incremental Backups on Linux](http://www.admin-magazine.com/Articles/Using-rsync-for-Backups).
* [Rsync full system backup](https://wiki.archlinux.org/index.php/Rsync#Full_system_backup).
