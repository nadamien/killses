#!/bin/bash

##get the current cursor count

curr_count=`sqlplus -silent schema_name/password@sid <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select a.value
from v$sesstat a, v$statname b, v$session s 
where a.statistic# = b.statistic# and s.sid=a.sid 
AND B.NAME = 'opened cursors current' 
AND A.VALUE >=500 and rownum < =1;
EXIT;
EOF`

##check for current cursor value if value is greater than 500 for the shell commands to execute

if (($curr_count >= 500)); then
  
echo "cursor limit exceeded"

now_time=$(date +"%T")
now=$(date +"%m-%d-%Y")

##get SID value

sid_val=`sqlplus -silent schema_name/password@sid <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select s.sid
from v$sesstat a, v$statname b, v$session s 
where a.statistic# = b.statistic# and s.sid=a.sid 
AND B.NAME = 'opened cursors current' 
AND A.VALUE >=500 and rownum < =1;
EXIT;
EOF`

##get serial value
serial_num=`sqlplus -silent schema_name/password@sid <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select s.serial# 
from v$sesstat a, v$statname b, v$session s 
where a.statistic# = b.statistic# and s.sid=a.sid 
AND B.NAME = 'opened cursors current' 
AND A.VALUE >=500 and rownum < =1;
EXIT;
EOF`

##killing process using the acquired sid and serial

p_kill=`sqlplus -silent schema_name/password@sid <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF

alter system kill session 'sid_val,serial_num' immediate;

EXIT;
EOF`

echo "process killed.."

##writing to a log file if killed
echo "writing log file..."
echo $now $now_time "|| " "curr val when killed":$curr_count "sid-"$sid_val "serial-" $serial_num $p_kill >> sessions_killed.log

else

 echo "cursor count is normal range --- no sessions killed"
 echo $now $now_time "|| " "no session killed" >> sessions_not_killed.log

 exit 0

fi

