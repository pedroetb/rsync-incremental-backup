# rsync-incremental-backup

Configurable bash script to send incremental backups of your data to a local or remote target.


## Description

This scripts does (as many as you want) incremental backups of the desired directory to another local or remote directory. The first directory acts as a master (doesn't get modified), making copies of itself at the second directory. Then, you can browse the second directory and get any file included into any previous backup.

Only incremental data is stored, so the size of backups doesn't grow so much.


## Configuration

You can set some configuration variables to customize the script:

* **src**: Path to source directory. Backups will include it's content.
* **dst**: Path to target directory. Backups will be placed here.
* **backupDepth**: Number of backups to keep. When limit is reached, the oldest get deleted.
* **remoteUser**: User to connect to remote host.
* **remoteHost**: Address of remote host.
* **pathBak0**: Directory inside **dst** where the more recent backup is stored.
* **pathBakN**: Directory inside **dst** where the rest of backups are stored.
* **nameBakN**: Name of incremental backup directories. An index will be added at the end to show how old they are.
* **logName**: Name given to log file generated at backup.
* **tempLogPath**: Path where the log file will be stored while backup is in progress. 
* **logFolderName**: Directory inside **dst** where the log files are stored.


## Usage

Once configured with your own values, you can simply run the script to begin the backup process.

Personally, I schedule it to run every week with [anacron](https://en.wikipedia.org/wiki/Anacron). This way, I don't need to remember running the script.


## References

I was inspired by [Incremental Backups on Linux](http://www.admin-magazine.com/Articles/Using-rsync-for-Backups) to make this script.
