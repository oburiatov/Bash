#!/bin/bash
MailTo='email@gmail.com'

# Get first parameter as config
# shellcheck disable=SC1090
source ${1} || echo "Need conf file as parameter"
#where ${1} is the path to variables

#Copy the latest backup to the storage directory
mv $REMOTE_DIR$MYSQLHOST$MYSQLPORT* $ARCHIVE_DIR


#Do full backup
#do dump with timestamp
DATE=$(date +"%Y-%m-%d-%H%M%S")
/usr/bin/mysqldump -h $MYSQLHOST -u $MYSQLUSER --all-databases  >  "$DIR/$MYSQLHOST$MYSQLPORT-$DATE".sql

if grep "Dump completed" "$DIR/$MYSQLHOST$MYSQLPORT-$DATE".sql
then
#Compress and copy to the remote host. Remove used file after each step.
GZIP=-9 tar -czf "$DIR/$MYSQLHOST$MYSQLPORT-$DATE".sql.tar.gz "$DIR/$MYSQLHOST$MYSQLPORT-$DATE".sql && rm -f "$DIR/$MYSQLHOST$MYSQLPORT-$DATE".sql
#scp "$DIR/$MYSQLHOST$MYSQLPORT-$DATE".sql.tar.gz "$REMOTE_MACHINE:$REMOTE_DIR" && rm -f "$DIR/$MYSQLHOST$MYSQLPORT-$DATE".sql.tar.gz

# Counter for the remote backups
RiEMOTE_BACKUP_COUNT=$(ssh $REMOTE_MACHINE "ls $ARCHIVE_DIR | grep $MYSQLHOST$MYSQLPORT | wc -l")
# Delete remote backups grater than $KEEP_BACKUP
 while (( REMOTE_BACKUP_COUNT > KEEP_BACKUP ))
  do
    ssh "$REMOTE_MACHINE" "ls -1tr $ARCHIVE_DIR$MYSQLHOST$MYSQLPORT* | head -n1 | xargs rm "
    REMOTE_BACKUP_COUNT=$(ssh $REMOTE_MACHINE "ls $ARCHIVE_DIR | grep $MYSQLHOST$MYSQLPORT | wc -l")
  done
else
# Notify if errors by email to the $MailTo
  echo "Server: $HOSTNAME File: $DIR/$MYSQLHOST$MYSQLPORT-$DATE.sql" | mailx -s "Dump MYSQL Error  $MYSQLHOST $MYSQLPORT" "$MailTo"
fi