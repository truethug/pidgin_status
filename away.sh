#!/bin/bash

#screen="DISPLAY=:0.0"

screen=$1

old=`cat /tmp/.awaytime`
new=`date -d -3sec +%Y%m%d%H%M%S`

status=`purple-remote 'getstatus'`
if [ $status == "available" ]
then
   echo $status
   echo `date -d now +%Y%m%d%H%M%S` > /tmp/.awaytime

   # when going away there are 2 messages back to back, only change status on second
   if [ $old -ge $new ]
   then
      purple-remote 'getstatusmessage' > /tmp/.message
      export $screen;/usr/bin/purple-remote setstatus?status=away;/usr/bin/purple-remote setstatus?message="afk"
   fi
elif [ $status == "away" ]
then
   echo $status
   if [ $old -le $new ]
   then
      message=`cat /tmp/.message`
      export $screen;/usr/bin/purple-remote setstatus?status=available;/usr/bin/purple-remote setstatus?message="$message"
      echo `date -d now +%Y%m%d%H%M%S` > /tmp/.awaytime
      rm /tmp/.message
   fi
fi

