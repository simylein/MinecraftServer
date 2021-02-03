#!/bin/bash
# minecraft server backup script

# this script is meant to be executed every hour by crontab

# for the sake of integrety of your backups,
# I would recommend not ot mess with this file.
# if you know what you are doing feel free to go ahead ;^)

# read server.functions file with error checking
if [[ -f "server.functions" ]]; then
	. ./server.functions
else
	echo "fatal: server.functions is missing" >> fatalerror.log
	echo "fatal: server.functions is missing"
	exit 1
fi

# read server.properties file with error checking
if ! [[ -f "server.properties" ]]; then
	echo "fatal: server.properties is missing" >> fatalerror.log
	echo "fatal: server.properties is missing"
	exit 1
fi

# read server.settings file with error checking
if [[ -f "server.settings" ]]; then
	. ./server.settings
else
	echo "fatal: server.settings is missing" >> fatalerror.log
	echo "fatal: server.settings is missing"
	exit 1
fi

# change to server directory with error checking
if [ -d "${serverdirectory}" ]; then
	cd ${serverdirectory}
else
	echo "fatal: serverdirectory is missing" >> fatalerror.log
	echo "fatal: serverdirectory is missing"
	exit 1
fi


# performs backup hourly every hour

# check if hourly backups are anabled
if [ ${dohourly} = true ]; then

	# write date and execute into logfiles
	echo "${date} executing backup-hourly script" >> ${screenlog}
	echo "${date} executing backup-hourly script" >> ${backuplog}

	# checks for the existence of a screen terminal
	if ! screen -list | grep -q "\.${servername}"; then
		echo -e "${yellow}server is not currently running!${nocolor}"
		echo "server is not currently running!" >> ${screenlog}
		echo "server is not currently running!" >> ${backuplog}
		echo "" >> ${backuplog}
		exit 1
	fi

	# check if world is bigger than diskspace
	if (( (${absoluteworldsize} + 65536) > ${absolutediskspace} )); then
		# ingame and logfile error output
		PrintToLogNotEnoughDiskSpace "hourly"
		PrintToScreenNotEnoughtDiskSpace "${newhourly}" "${oldhourly}"
		exit 1
	fi

	# check if there is no backup from the current hour
	if ! [  -sw "${backupdirectory}/hourly/${servername}-${newhourly}.tar.gz" ]; then
		tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/hourly/${servername}-${newhourly}.tar.gz
	else
		echo "warning: backup already exists!" >> ${backuplog}
		echo "" >> ${backuplog}
		exit 1
	fi

	# check if there is a new backup
	if [ -sw "${backupdirectory}/hourly/${servername}-${newhourly}.tar.gz" ]; then
		# check if an old backup exists an remove it
		if [ -sw "${backupdirectory}/hourly/${servername}-${oldhourly}.tar.gz" ]; then
			rm ${backupdirectory}/hourly/${servername}-${oldhourly}.tar.gz
		fi
		# read server.settings file again with error checking
		if [[ -f "server.settings" ]]; then
			. ./server.settings
		else
			echo "fatal: server.settings is missing" >> fatalerror.log
			echo "fatal: server.settings is missing"
			exit 1
		fi
		# ingame and logfile success output
		PrintToScreenBackupSuccess "${newhourly}" "${oldhourly}"
		PrintToLogBackupSuccess "${newhourly}" "${oldhourly}"
	else
		# ingame and logfile error output
		PrintToScreenBackupError "${newhourly}" "${oldhourly}"
		PrintToLogBackupError
	fi

else
	# write date and execute into logfiles
	echo "${date} executing backup-hourly script" >> ${screenlog}
	echo "${date} executing backup-hourly script" >> ${backuplog}

	# write to logfiles that it's disabled
	echo "backup-hourly is disabled" >> ${backuplog}
	echo "" >> ${backuplog}
fi


# performs backup daily if it is 22:??

# check if it is 22:??
hours=$(date +"%H")
if [ ${hours} -eq 22 ]; then

	# check if daily backups are anabled
	if [ ${dodaily} = true ]; then

		# write date and execute into logfiles
		echo "${date} executing backup-daily script" >> ${screenlog}
		echo "${date} executing backup-daily script" >> ${backuplog}

		# checks for the existence of a screen terminal
		if ! screen -list | grep -q "\.${servername}"; then
			echo -e "${yellow}server is not currently running!${nocolor}"
			echo "server is not currently running!" >> ${screenlog}
			echo "server is not currently running!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if world is bigger than diskspace
		if (( (${absoluteworldsize} + ${diskspacepadding}) > ${absolutediskspace} )); then
			# ingame and logfile error output
			PrintToLogNotEnoughDiskSpace "daily"
			PrintToScreenNotEnoughtDiskSpace "${newdaily}" "${olddaily}"
			exit 1
		fi

		# check if there is no backup from the current day
		if ! [ -sw "${backupdirectory}/daily/${servername}-${newdaily}.tar.gz" ]; then
			tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/hourly/${servername}-${newdaily}.tar.gz
		else
			echo "warning: backup already exists!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if there is a new backup
		if [ -sw "${backupdirectory}/daily/${servername}-${newdaily}.tar.gz" ]; then
			# check if an old backup exists an remove it
			if [ -sw "${backupdirectory}/daily/${servername}-${olddaily}.tar.gz" ]; then
				rm ${backupdirectory}/daily/${servername}-${olddaily}.tar.gz
			fi
			# read server.settings file again with error checking
			if [[ -f "server.settings" ]]; then
				. ./server.settings
			else
				echo "fatal: server.settings is missing" >> fatalerror.log
				echo "fatal: server.settings is missing"
				exit 1
			fi
			# ingame and logfile success output
			PrintToScreenBackupSuccess "${newdaily}" "${olddaily}"
			PrintToLogBackupSuccess "${newdaily}" "${olddaily}"
		else
			# ingame and logfile error output
			PrintToScreenBackupError "${newdaily}" "${olddaily}"
			PrintToLogBackupError
		fi

	else
		# write date and execute into logfiles
		echo "${date} executing backup-daily script" >> ${screenlog}
		echo "${date} executing backup-daily script" >> ${backuplog}

		# write to logfiles that it's disabled
		echo "backup-daily is disabled" >> ${backuplog}
		echo "" >> ${backuplog}
	fi
fi


# performs backup weekly if it is 22:?? and Sunday

# check if it is 22:?? and Sunday
hours=$(date +"%H")
weekday=$(date +"%u")
if [ ${hours} -eq 22 ] && [ ${weekday} -eq 7 ]; then

	# check if weekly backups are enabled
	if [ ${doweekly} = true ]; then

		# write date and execute into logfiles
		echo "${date} executing backup-weekly script" >> ${screenlog}
		echo "${date} executing backup-weekly script" >> ${backuplog}

		# checks for the existence of a screen terminal
		if ! screen -list | grep -q "\.${servername}"; then
			echo -e "${yellow}server is not currently running!${nocolor}"
			echo "server is not currently running!" >> ${screenlog}
			echo "server is not currently running!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if world is bigger than diskspace
		if (( (${absoluteworldsize} + ${diskspacepadding}) > ${absolutediskspace} )); then
			# ingame and logfile error output
			PrintToLogNotEnoughDiskSpace "weekly"
			PrintToScreenNotEnoughtDiskSpace "${newweekly}" "${oldweekly}"
			exit 1
		fi

		# check if there is no backup from the current week
		if ! [ -sw "${backupdirectory}/weekly/${servername}-${newweekly}.tar.gz" ]; then
			tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/hourly/${servername}-${newweekly}.tar.gz
		else
			echo "warning: backup already exists!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if there is a new backup
		if [ -sw "${backupdirectory}/weekly/${servername}-${newweekly}.tar.gz" ]; then
			# check if an old backup exists an remove it
			if [ -sw "${backupdirectory}/weekly/${servername}-${oldweekly}.tar.gz" ]; then
				rm ${backupdirectory}/weekly/${servername}-${oldweekly}.tar.gz
			fi
			# read server.settings file again with error checking
			if [[ -f "server.settings" ]]; then
				. ./server.settings
			else
				echo "fatal: server.settings is missing" >> fatalerror.log
				echo "fatal: server.settings is missing"
				exit 1
			fi
			# ingame and logfile success output
			PrintToScreenBackupSuccess "${newweekly}" "${oldweekly}"
			PrintToLogBackupSuccess "${newweekly}" "${oldweekly}"
		else
			# ingame and logfile error output
			PrintToScreenBackupError "${newweekly}" "${oldweekly}"
			PrintToLogBackupError
		fi

	else
		# write date and execute into logfiles
		echo "${date} executing backup-weekly script" >> ${screenlog}
		echo "${date} executing backup-weekly script" >> ${backuplog}

		# write to logfiles that it's disabled
		echo "backup-weekly is disabled" >> ${backuplog}
		echo "" >> ${backuplog}
	fi
fi


# performs backup monthly if it is 22:?? and the first day of a month

# check if it is 22:?? and the first day of month
hours=$(date +"%H")
dayofmonth=$(date +"%d")
if [ ${hours} -eq 22 ] && [ ${dayofmonth} -eq 1 ]; then

	# check if monthly backups are enabled
	if [ ${domonthly} = true ]; then

		# write date and execute into logfiles
		echo "${date} executing backup-monthly script" >> ${screenlog}
		echo "${date} executing backup-monthly script" >> ${backuplog}

		# checks for the existence of a screen terminal
		if ! screen -list | grep -q "\.${servername}"; then
			echo -e "${yellow}server is not currently running!${nocolor}"
			echo "server is not currently running!" >> ${screenlog}
			echo "server is not currently running!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if world is bigger than diskspace
		if (( (${absoluteworldsize} + ${diskspacepadding}) > ${absolutediskspace} )); then
			# ingame and logfile error output
			PrintToLogNotEnoughDiskSpace "monthly"
			PrintToScreenNotEnoughtDiskSpace "${newmonthly}" "${oldmonthly}"
			exit 1
		fi

		# check if there is no backup from the current month
		if ! [ -sw "${backupdirectory}/monthly/${servername}-${newmonthly}.tar.gz" ]; then
			tar -czf world.tar.gz world && mv ${serverdirectory}/world.tar.gz ${backupdirectory}/hourly/${servername}-${newmonthly}.tar.gz
		else
			echo "warning: backup already exists!" >> ${backuplog}
			echo "" >> ${backuplog}
			exit 1
		fi

		# check if there is a new backup
		if [ -sw "${backupdirectory}/monthly/${servername}-${newmonthly}.tar.gz" ]; then
			# check if an old backup exists an remove it
			if [ -sw "${backupdirectory}/monthly/${servername}-${oldmonthly}.tar.gz" ]; then
				rm ${backupdirectory}/monthly/${servername}-${oldmonthly}.tar.gz
			fi
			# read server.settings file again with error checking
			if [[ -f "server.settings" ]]; then
				. ./server.settings
			else
				echo "fatal: server.settings is missing" >> fatalerror.log
				echo "fatal: server.settings is missing"
				exit 1
			fi
			# ingame and logfile success output
			PrintToScreenBackupSuccess "${newmonthly}" "${oldmonthly}"
			PrintToLogBackupSuccess "${newmonthly}" "${oldmonthly}"
		else
			# ingame and logfile error output
			PrintToScreenBackupError "${newmonthly}" "${oldmonthly}"
			PrintToLogBackupError
		fi

	else
		# write date and execute into logfiles
		echo "${date} executing backup-weekly script" >> ${screenlog}
		echo "${date} executing backup-weekly script" >> ${backuplog}

		# write to logfiles that it's disabled
		echo "backup-weekly is disabled" >> ${backuplog}
		echo "" >> ${backuplog}
	fi
fi
