#!/bin/bash

# Add launcher.sh to autostart and make sure display in correct below

# Folder this script is in
SCRIPT_HOME=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

#screen=`env|grep DISPLAY`
#screen="DISPLAY=:0.0"
screen=$1

# If this exists use webdav
if [ -f ~/.ssh/webdav ]
then
   while read line
   do
      # user:pass
      secure=$line
      read line
      # https://server.com:port/path/calendar.ics
      server=$line
      echo $server
   curl -k --user "$secure" "$server" > ~/.thunderbird/Work.ics
   done < ~/.ssh/webdav
fi

egrep "DTSTART|DTEND|SUMMARY|STATUS" ~/.thunderbird/Work.ics > /tmp/cleaned

# remove old at jobs
for i in `atq|awk '{print $1}'`
do
   atrm $i
done

Microsoft=`grep X-MICROSOFT-CDO-BUSYSTATUS: /tmp/cleaned`
if [ "$Microsoft" == "" ]
then
   while read -r line
   do
      summary=`echo $line | tr -d '\r' | grep ^SUMMARY`
      if [ "$summary" != "" -a "`echo $summary | grep -i Canceled`" == "" ]
      then
         summary=`echo $line | tr -d '\r' | cut -d: -f2-`
         summary=`echo "$summary" | sed 's/\"/\\\"/g'`

         read line
         status=`echo $line | tr -d '\r' | cut -d: -f2-`
         echo Summary: $summary Status: $status

         read line
         TZ=`echo $line | cut -d= -f2| cut -d: -f1`
         startDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
         startDay=`date -d "$startDay" +%m/%d/%y`
         startTime=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-4`
         startAt=`date --date="TZ=\"$TZ\" $startTime" | awk '{print $4}' | cut -d: -f1,2` 
    
         read line
         endDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
         endDay=`date -d "$endDay" +%m/%d/%y`
         endTime=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-4`
         endTime=`date --date="TZ=\"$TZ\" $endTime" | awk '{print $4}' | cut -d: -f1,2`
         # end one minute early to avoid conflict with next item starting at the same time
         endTime=`date -d "$endTime 1 min ago" +%R`

         if [ "$status" != "TENTATIVE" -a "$status" != "CANCELED" -a "$startTime" != "" ] 
         then
            # Add new at jobs
            echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"  | at $startAt $startDay"
            echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"" | at $startAt $startDay
            echo "export $screen;/usr/bin/purple-remote setstatus?status=available;/usr/bin/purple-remote setstatus?message=" | at $endTime $endDay
         fi
      fi
   done < /tmp/cleaned
else # Microsoft format
   while read -r line
   do
      summary=`echo $line | tr -d '\r' | grep ^SUMMARY`
      if [ "$summary" != "" -a "`echo $summary | grep -i Canceled`" == "" ]
      then
         summary=`echo $line | tr -d '\r' | cut -d: -f2-`
         summary=`echo "$summary" | sed 's/\"/\\\"/g'`

         read line
         TZ=`echo $line | cut -d= -f2| cut -d: -f1`
         startDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
         startDay=`date -d "$startDay" +%m/%d/%y`
         startTime=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-4`
         startAt=`date --date="TZ=\"$TZ\" $startTime" | awk '{print $4}' | cut -d: -f1,2` 
    
         read line
         endDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
         endDay=`date -d "$endDay" +%m/%d/%y`
         endTime=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-4`
         endTime=`date --date="TZ=\"$TZ\" $endTime" | awk '{print $4}' | cut -d: -f1,2`
         # end one minute early to avoid conflict with next item starting at the same time
         endTime=`date -d "$endTime 1 min ago" +%R`

         read line
         status=`echo $line | tr -d '\r' | cut -d: -f2-`
         echo Summary: $summary Status: $status

         if [ "$status" != "TENTATIVE" -a "$status" != "CANCELED" -a "$startTime" != "" ] 
         then
            # Add new at jobs
            echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"  | at $startAt $startDay"
            echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"" | at $startAt $startDay
            echo "export $screen;/usr/bin/purple-remote setstatus?status=available;/usr/bin/purple-remote setstatus?message=" | at $endTime $endDay
         fi
      fi
   done < /tmp/cleaned
fi
rm /tmp/cleaned

# Run the script again every 5 min ( 1 min earlier if on the 0 or 5 to avoid removing at jobs for current minute
minute=`date|cut -d: -f2`
if [ `expr $minute % 5` -eq 0 ]
then
   echo "$SCRIPT_HOME/pidgin_status.sh $screen" | at now + 4 minutes
else
   echo "$SCRIPT_HOME/pidgin_status.sh $screen" | at now + 5 minutes
fi

