#!/bin/bash
# minecraft server backup script

# this script is meant to be executed every hour by crontab
# 0 * * * * cd ${serverdirectory} ./backup.sh

# if you want you can change the time of day on which
# daily backups are made as an example in server.settings, but please beware:

# for the sake of integrity of your backups,
# I would strongly recommend not to mess with this file.
# if you really know what you are doing feel free to go ahead ;^)

# root safety check
if [ $(id -u) = 0 ]; then
	echo "$(tput bold)$(tput setaf 1)please do not run me as root :( - this is dangerous!$(tput sgr0)"
	exit 1
fi

# read server.functions file with error checking
if [[ -s "server.functions" ]]; then
	. ./server.functions
else
	echo "$(date) fatal: server.functions is missing" >> fatalerror.log
	echo "$(tput setaf 1)fatal: server.functions is missing$(tput sgr0)"
	exit 1
fi

# read server.properties file with error checking
if ! [[ -s "server.properties" ]]; then
	echo "$(date) fatal: server.properties is missing" >> fatalerror.log
	echo "$(tput setaf 1)fatal: server.properties is missing$(tput sgr0)"
	exit 1
fi

# read server.settings file with error checking
if [[ -s "server.settings" ]]; then
	. ./server.settings
else
	echo "$(date) fatal: server.settings is missing" >> fatalerror.log
	echo "$(tput setaf 1)fatal: server.settings is missing$(tput sgr0)"
	exit 1
fi

# change to server directory with error checking
if [ -d "${serverdirectory}" ]; then
	cd ${serverdirectory}
else
	echo "$(date) fatal: serverdirectory is missing" >> fatalerror.log
	echo "$(tput setaf 1)fatal: serverdirectory is missing$(tput sgr0)"
	exit 1
fi

# parsing script arguments
ParseScriptArguments "$@"

# test if all categories for backups exists if not create them
CheckBackupDirectoryIntegrity


# check if hourly backups are anabled
if [ ${dohourly} = true ]; then

	# write date and execute into logfiles
	echo "${date} executing backup-hourly script" >> ${screenlog}
	echo "${date} executing backup-hourly script" >> ${backuplog}
	CheckDebug "executing backup-hourly script" >> ${debuglog}
	
	# start milliseconds timer
	before=$(date +%s%3N)

	# checks for the existence of a screen terminal
	if ! screen -list | grep -q "\.${servername}"; then
		echo "${yellow}server is not currently running!${nocolor}"
		echo "info: server is not currently running!" >> ${screenlog}
		echo "info: server is not currently running!" >> ${backuplog}
		echo "" >> ${backuplog}
		exit 1
	fi

	# check if world is bigger than diskspace
	if (( (${absoluteworldsize} + ${diskspacepadding}) > ${absolutediskspace} )); then
		# ingame, terminal and logfile error output
		PrintToScreenNotEnoughtDiskSpace "${newhourly}" "${oldhourly}"
		PrintToLogNotEnoughDiskSpace "hourly"
		PrintToTerminalNotEnoughDiskSpace "hourly"
		exit 1
	fi

	# check if disk space is getting low
	if (( (${absoluteworldsize} + ${diskspacewarning}) > ${absolutediskspace} )); then
		PrintToScreenDiskSpaceWarning "${newhourly}" "${oldhourly}"
		PrintToLogDiskSpaceWarning
		PrintToTerminalDiskSpaceWarning
	fi

	# check if there is no backup from the current hour
	if ! [[ -s "${backupdirectory}/hourly/${servername}-${newhourly}.tar.gz" ]]; then
		if [[ -s "world.tar.gz" ]]; then
			rm world.tar.gz
		fi
		PrintToScreen "save-off"
		tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/hourly/${servername}-${newhourly}.tar.gz
		PrintToScreen "save-on"
	else
		PrintToScreenBackupAlreadyExists "${newhourly}" "${oldhourly}"
		PrintToLogBackupAlreadyExists "hourly"
		PrintToTerminalBackupAlreadyExists "hourly"
		exit 1
	fi

	# check if there is a new backup
	if [[ -s "${backupdirectory}/hourly/${servername}-${newhourly}.tar.gz" ]]; then
		# check if an old backup exists an remove it
		if [[ -s "${backupdirectory}/hourly/${servername}-${oldhourly}.tar.gz" ]]; then
			rm ${backupdirectory}/hourly/${servername}-${oldhourly}.tar.gz
		fi
		# stop milliseconds timer
		after=$(date +%s%3N)
		# calculate time spent on backup process
		timespent=$((${after}-${before}))
		# get compressed backup size
		compressedbackup=$(du -sh ${backupdirectory}/hourly/${servername}-${newhourly}.tar.gz | cut -f1)
		# read server.settings file again
		. ./server.settings
		# ingame and logfile success output
		PrintToScreenBackupSuccess "${newhourly}" "${oldhourly}"
		PrintToLogBackupSuccess "${newhourly}" "${oldhourly}"
		PrintToTerminalBackupSuccess "${newhourly}" "${oldhourly}"
	else
		# ingame and logfile error output
		PrintToScreenBackupError "${newhourly}" "${oldhourly}"
		PrintToLogBackupError
		PrintToTerminalBackupError
	fi

else
	# write to logfiles that it's disabled
	CheckDebug "info: backup-hourly is disabled" >> ${debuglog}
	echo "info: backup-hourly is disabled" >> ${backuplog}
	echo "" >> ${backuplog}
fi


# check if it is the right time
if [ ${hours} -eq ${dailybackuptime} ]; then

	# write date and execute into logfiles
	echo "${date} executing backup-daily script" >> ${screenlog}
	echo "${date} executing backup-daily script" >> ${backuplog}
	CheckDebug "executing backup-daily script" >> ${debuglog}

	# check if daily backups are anabled
	if [ ${dodaily} = true ]; then

		# start milliseconds timer
		before=$(date +%s%3N)

		# checks for the existence of a screen terminal
		if ! screen -list | grep -q "\.${servername}"; then
			echo "${yellow}server is not currently running!${nocolor}"
			echo "info: server is not currently running!" >> ${screenlog}
			echo "info: server is not currently running!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if world is bigger than diskspace
		if (( (${absoluteworldsize} + ${diskspacepadding}) > ${absolutediskspace} )); then
			# ingame, terminal and logfile error output
			PrintToScreenNotEnoughtDiskSpace "${newdaily}" "${olddaily}"
			PrintToLogNotEnoughDiskSpace "daily"
			PrintToTerminalNotEnoughDiskSpace "daily"
			exit 1
		fi

		# check if disk space is getting low
		if (( (${absoluteworldsize} + ${diskspacewarning}) > ${absolutediskspace} )); then
			PrintToScreenDiskSpaceWarning "${newdaily}" "${olddaily}"
			PrintToLogDiskSpaceWarning
			PrintToTerminalDiskSpaceWarning
		fi

		# check if there is no backup from the current day
		if ! [[ -s "${backupdirectory}/daily/${servername}-${newdaily}.tar.gz" ]]; then
			if [[ -s "world.tar.gz" ]]; then
				rm world.tar.gz
			fi
			PrintToScreen "save-off"
			tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/daily/${servername}-${newdaily}.tar.gz
			PrintToScreen "save-on"
		else
			PrintToScreenBackupAlreadyExists "${newdaily}" "${olddaily}"
			PrintToLogBackupAlreadyExists "daily"
			PrintToTerminalBackupAlreadyExists "daily"
			exit 1
		fi

		# check if there is a new backup
		if [[ -s "${backupdirectory}/daily/${servername}-${newdaily}.tar.gz" ]]; then
			# check if an old backup exists an remove it
			if [[ -s "${backupdirectory}/daily/${servername}-${olddaily}.tar.gz" ]]; then
				rm ${backupdirectory}/daily/${servername}-${olddaily}.tar.gz
			fi
			# stop milliseconds timer
			after=$(date +%s%3N)
			# calculate time spent on backup process
			timespent=$((${after}-${before}))
			# get compressed backup size
			compressedbackup=$(du -sh ${backupdirectory}/daily/${servername}-${newdaily}.tar.gz | cut -f1)
			# read server.settings file again
			. ./server.settings
			# ingame and logfile success output
			PrintToScreenBackupSuccess "${newdaily}" "${olddaily}"
			PrintToLogBackupSuccess "${newdaily}" "${olddaily}"
			PrintToTerminalBackupSuccess "${newdaily}" "${olddaily}"
		else
			# ingame and logfile error output
			PrintToScreenBackupError "${newdaily}" "${olddaily}"
			PrintToLogBackupError
			PrintToTerminalBackupError
		fi

	else
		# write to logfiles that it's disabled
		CheckDebug "info: backup-daily is disabled" >> ${debuglog}
		echo "info: backup-daily is disabled" >> ${backuplog}
		echo "" >> ${backuplog}
	fi
fi


# check if it is the right time and weekday
if [ ${hours} -eq ${dailybackuptime} ] && [ ${weekday} -eq ${weeklybackupday} ]; then

	# write date and execute into logfiles
	echo "${date} executing backup-weekly script" >> ${screenlog}
	echo "${date} executing backup-weekly script" >> ${backuplog}
	CheckDebug "executing backup-weekly script" >> ${debuglog}

	# check if weekly backups are enabled
	if [ ${doweekly} = true ]; then

		# start milliseconds timer
		before=$(date +%s%3N)

		# checks for the existence of a screen terminal
		if ! screen -list | grep -q "\.${servername}"; then
			echo "${yellow}server is not currently running!${nocolor}"
			echo "info: server is not currently running!" >> ${screenlog}
			echo "info: server is not currently running!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if world is bigger than diskspace
		if (( (${absoluteworldsize} + ${diskspacepadding}) > ${absolutediskspace} )); then
			# ingame, terminal  and logfile error output
			PrintToScreenNotEnoughtDiskSpace "${newweekly}" "${oldweekly}"
			PrintToLogNotEnoughDiskSpace "weekly"
			PrintToTerminalNotEnoughDiskSpace "weekly"
			exit 1
		fi

		# check if disk space is getting low
		if (( (${absoluteworldsize} + ${diskspacewarning}) > ${absolutediskspace} )); then
			PrintToScreenDiskSpaceWarning "${newweekly}" "${oldweekly}"
			PrintToLogDiskSpaceWarning
			PrintToTerminalDiskSpaceWarning
		fi

		# check if there is no backup from the current week
		if ! [[ -s "${backupdirectory}/weekly/${servername}-${newweekly}.tar.gz" ]]; then
			if [[ -s "world.tar.gz" ]]; then
				rm world.tar.gz
			fi
			PrintToScreen "save-off"
			tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/weekly/${servername}-${newweekly}.tar.gz
			PrintToScreen "save-on"
		else
			PrintToScreenBackupAlreadyExists "${newweekly}" "${oldweekly}"
			PrintToLogBackupAlreadyExists "weekly"
			PrintToTerminalBackupAlreadyExists "weekly"
			exit 1
		fi

		# check if there is a new backup
		if [[ -s "${backupdirectory}/weekly/${servername}-${newweekly}.tar.gz" ]]; then
			# check if an old backup exists an remove it
			if [[ -s "${backupdirectory}/weekly/${servername}-${oldweekly}.tar.gz" ]]; then
				rm ${backupdirectory}/weekly/${servername}-${oldweekly}.tar.gz
			fi
			# stop milliseconds timer
			after=$(date +%s%3N)
			# calculate time spent on backup process
			timespent=$((${after}-${before}))
			# get compressed backup size
			compressedbackup=$(du -sh ${backupdirectory}/weekly/${servername}-${newweekly}.tar.gz | cut -f1)
			# read server.settings file again
			. ./server.settings
			# ingame and logfile success output
			PrintToScreenBackupSuccess "${newweekly}" "${oldweekly}"
			PrintToLogBackupSuccess "${newweekly}" "${oldweekly}"
			PrintToTerminalBackupSuccess "${newweekly}" "${oldweekly}"
		else
			# ingame and logfile error output
			PrintToScreenBackupError "${newweekly}" "${oldweekly}"
			PrintToLogBackupError
			PrintToTerminalBackupError
		fi

	else
		# write to logfiles that it's disabled
		CheckDebug "info: backup-weekly is disabled" >> ${debuglog}
		echo "info: backup-weekly is disabled" >> ${backuplog}
		echo "" >> ${backuplog}
	fi
fi


# check if it is the right time and day of the month
if [ ${hours} -eq ${dailybackuptime} ] && [ ${dayofmonth} -eq ${monthlybackupday} ]; then

	# write date and execute into logfiles
	echo "${date} executing backup-monthly script" >> ${screenlog}
	echo "${date} executing backup-monthly script" >> ${backuplog}
	CheckDebug "executing backup-monthly script" >> ${debuglog}

	# check if monthly backups are enabled
	if [ ${domonthly} = true ]; then

		# start milliseconds timer
		before=$(date +%s%3N)

		# checks for the existence of a screen terminal
		if ! screen -list | grep -q "\.${servername}"; then
			echo "${yellow}server is not currently running!${nocolor}"
			echo "info: server is not currently running!" >> ${screenlog}
			echo "info: server is not currently running!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if world is bigger than diskspace
		if (( (${absoluteworldsize} + ${diskspacepadding}) > ${absolutediskspace} )); then
			# ingame, terminal and logfile error output
			PrintToScreenNotEnoughtDiskSpace "${newmonthly}" "${oldmonthly}"
			PrintToLogNotEnoughDiskSpace "monthly"
			PrintToTerminalNotEnoughDiskSpace "monthly"
			exit 1
		fi

		# check if disk space is getting low
		if (( (${absoluteworldsize} + ${diskspacewarning}) > ${absolutediskspace} )); then
			PrintToScreenDiskSpaceWarning "${newmonthly}" "${oldmonthly}"
			PrintToLogDiskSpaceWarning
			PrintToTerminalDiskSpaceWarning
		fi

		# check if there is no backup from the current month
		if ! [[ -s "${backupdirectory}/monthly/${servername}-${newmonthly}.tar.gz" ]]; then
			if [[ -s "world.tar.gz" ]]; then
				rm world.tar.gz
			fi
			PrintToScreen "save-off"
			tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/monthly/${servername}-${newmonthly}.tar.gz
			PrintToScreen "save-on"
		else
			PrintToScreenBackupAlreadyExists "${newmonthly}" "${oldmonthly}"
			PrintToLogBackupAlreadyExists "monthly"
			PrintToTerminalBackupAlreadyExists "monthly"
			exit 1
		fi

		# check if there is a new backup
		if [[ -s "${backupdirectory}/monthly/${servername}-${newmonthly}.tar.gz" ]]; then
			# check if an old backup exists an remove it
			if [[ -s "${backupdirectory}/monthly/${servername}-${oldmonthly}.tar.gz" ]]; then
				rm ${backupdirectory}/monthly/${servername}-${oldmonthly}.tar.gz
			fi
			# stop milliseconds timer
			after=$(date +%s%3N)
			# calculate time spent on backup process
			timespent=$((${after}-${before}))
			# get compressed backup size
			compressedbackup=$(du -sh ${backupdirectory}/monthly/${servername}-${newmonthly}.tar.gz | cut -f1)
			# read server.settings file again
			. ./server.settings
			# ingame and logfile success output
			PrintToScreenBackupSuccess "${newmonthly}" "${oldmonthly}"
			PrintToLogBackupSuccess "${newmonthly}" "${oldmonthly}"
			PrintToTerminalBackupSuccess "${newmonthly}" "${oldmonthly}"
		else
			# ingame and logfile error output
			PrintToScreenBackupError "${newmonthly}" "${oldmonthly}"
			PrintToLogBackupError
			PrintToTerminalBackupError
		fi

	else
		# write to logfiles that it's disabled
		CheckDebug "info: backup-monthly is disabled" >> ${debuglog}
		echo "info: backup-monthly is disabled" >> ${backuplog}
		echo "" >> ${backuplog}
	fi
fi
