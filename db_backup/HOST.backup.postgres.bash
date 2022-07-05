#!/bin/bash
MailTo='email@gmail.com'

# Get first parameter as config
# shellcheck disable=SC1090
source ${1} || echo "Need conf file as parameter"
#where ${1} is the name of .conf file


#Copy the latest backup to the storage directory
mv $REMOTE_DIR$PGHOST$PGPORT* $ARCHIVE_DIR

#Do full backup
# do dump with timestamp
DATE=$(date +"%Y-%m-%d-%H%M%S")
$PG_DUMPALL_PATH -h $PGHOST -U $PGUSER -p $PGPORT >  "$DIR/$PGHOST$PGPORT-$DATE".out
#chmod 777 "$DIR/$PGHOST$PGPORT-$DATE".out

if grep "PostgreSQL database dump complete" "$DIR/$PGHOST$PGPORT-$DATE".out
then
#Compress and copy to the remote host. Remove used file after each step.
GZIP=-9 tar -czf "$DIR/$PGHOST$PGPORT-$DATE".out.tar.gz "$DIR/$PGHOST$PGPORT-$DATE".out && rm -f "$DIR/$PGHOST$PGPORT-$DATE".out
#scp "$DIR/$PGHOST$PGPORT-$DATE".out.tar.gz "$REMOTE_MACHINE:$REMOTE_DIR" && rm -f "$DIR/$PGHOST$PGPORT-$DATE".out.tar.gz

# Counter for the remote backups
REMOTE_BACKUP_COUNT=$(ssh $REMOTE_MACHINE "ls $ARCHIVE_DIR | grep $PGHOST$PGPORT | wc -l")
# Delete remote backups grater than $KEEP_BACKUP
 while (( REMOTE_BACKUP_COUNT > KEEP_BACKUP ))
  do
    ssh "$REMOTE_MACHINE" "ls -1tr $ARCHIVE_DIR$PGHOST$PGPORT* | head -n1 | xargs rm "
    REMOTE_BACKUP_COUNT=$(ssh $REMOTE_MACHINE "ls $ARCHIVE_DIR | grep $PGHOST$PGPORT | wc -l")
  done
else
# Notify if errors by email to the $MailTo
  echo "Server: $HOSTNAME File: $DIR/$PGHOST$PGPORT-$DATE.sql" | mailx -s "Dump PostgreSQL Error  $PGHOST $PGPORT" "$MailTo"
fi