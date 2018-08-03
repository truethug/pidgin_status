#!/bin/bash

# Add launcher.sh to autostart and make sure DISPLAY is correct

# Folder this script is in
SCRIPT_HOME=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

#screen=`env|grep DISPLAY`
#screen="DISPLAY=:0.0"
screen=$1
calendar=~/.thunderbird/Work.ics

function getSummary() 
{
   summary=`echo $line | tr -d '\r' | cut -d: -f2-`
   summary=`echo "$summary" | sed 's/\"/\\\"/g'`
}

function getStatus()
{
   status=`echo $line | tr -d '\r' | cut -d: -f2-`
}

function getStart()
{
   TZ=`echo $line | cut -d= -f2| cut -d: -f1`
   TZ=`echo $TZ | sed 's/\"//g'`
   startDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
   startDay=`date -d "$startDay" +%m/%d/%y`
   startTime=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-4`
   if [ "$Microsoft" == "" ]
   then
      startTime=`date --date="TZ=\"$TZ\" $startTime" | awk '{print $4}' | cut -d: -f1,2`
   fi
}

function getEnd()
{
   TZ=`echo $line | cut -d= -f2| cut -d: -f1`
   TZ=`echo $TZ | sed 's/\"//g'`
   endDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
   endDay=`date -d "$endDay" +%m/%d/%y`
   endTime=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-4`
   if [ "$Microsoft" == "" ]
   then
      endTime=`date --date="TZ=\"$TZ\" $endTime" | awk '{print $4}' | cut -d: -f1,2`
   fi
   # end one minute early to avoid conflict with next item starting at the same time
   endTime=`date -d "$endTime 1 min ago" +%R`
}

function getInfo()
{
   if [ "`echo $line | grep BEGIN:VEVENT`" == "" ]
   then
      if [ "`echo $line | grep ^SUMMARY`" != "" ]
      then
         getSummary
         echo $summary
      elif [ "`echo $line | grep STATUS:`" != "" ]
      then
         getStatus
         echo $status
      elif [ "`echo $line | grep ^DTSTART`" != "" ]
      then
         getStart
         echo $startDay $startTime
      elif [ "`echo $line | grep ^DTEND`" != "" ]
      then
         getEnd
         echo $endDay $endTime
      fi
   else
      stop="true"
   fi
}

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
      curl -k --user "$secure" "$server" > $calendar
   done < ~/.ssh/webdav
fi

egrep "DTSTART|DTEND|SUMMARY|STATUS|BEGIN:VEVENT" $calendar > /tmp/cleaned
m1=`md5sum /tmp/cleaned | awk '{print $1}'`
m2=`md5sum /tmp/cleaned2 | awk '{print $1}'`

if [ "$m1" != "$m2" ]
then

   Microsoft=`grep X-MICROSOFT-CDO-BUSYSTATUS: /tmp/cleaned`

   # remove old at jobs
   for i in `atq|awk '{print $1}'`
   do
      atrm $i
   done

   while read -r line
   do
      summary=""
      status=""
      startTime=""
      endTime=""
      stop=""
      begin=`echo $line | tr -d '\r' | grep BEGIN:VEVENT`
      if [ "$begin" != "" ]
      then
         echo ""
         echo ""
         echo ""

         read line
         getInfo

         if [ "$stop" != "true" ]
         then
            read line
            getInfo
         fi 

         if [ "$stop" != "true" ]
         then
            read line
            getInfo
         fi 

         if [ "$stop" != "true" ]
         then
            read line
            getInfo
         fi 

         if [ "$status" != "TENTATIVE" -a "$status" != "CANCELED" -a "$startTime" != "" -a "`echo $summary | grep -i Canceled`" == "" -a "`echo $summary | grep -i Tentative`" == ""] 
         then
            # Add new at jobs
            echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"  | at $startTime $startDay"
            echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"" | at $startTime $startDay
            echo "export $screen;/usr/bin/purple-remote setstatus?status=available;/usr/bin/purple-remote setstatus?message=" | at $endTime $endDay
         fi
      fi
   done < /tmp/cleaned
fi
mv /tmp/cleaned /tmp/cleaned2

# Run the script again every 5 min ( 1 min earlier if on the 0 or 5 to avoid removing at jobs for current minute
minute=`date|cut -d: -f2`
if [ `expr $minute % 5` -eq 0 ]
then
   echo "$SCRIPT_HOME/pidgin_status.sh $screen" | at now + 4 minutes
else
   echo "$SCRIPT_HOME/pidgin_status.sh $screen" | at now + 5 minutes
fi

