PRG="$0"
porteureka=8761
portconfig=8888
portactivemq=20891
porttaskengine=20881
porti18nserver=20888
portcmdb=20883
portgatherframe=20882
portvspheremanage=20886
portvsphereagent=20887
portmessage=20889
portalarmcenter=20885
porttaskjob=20884
portservicemonitor=20890
portzuulmanager=20892
porteseemanager=20893
portgmccmanager=20894
portimtask=28085
portimapigateway=28082
portimprovider=28084
portim3rdinf=28086
portimweb=8443
#portuniviewmanager=20895
sleeptime=5

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done
PRGDIR=`dirname "$PRG"`
  
CURRENT_DIR=`cd "$PRGDIR" >/dev/null; pwd`

echo "nodeplan=""$nodeplan"
echo "nodetype=""$nodetype"
echo "nodeno=""$nodeno"

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "1" ] ; then
echo 'start eureka'
pIDeureka=`lsof -i :$porteureka|grep  "LISTEN" | awk '{print $2}'`
echo $pIDeureka
if [ "$pIDeureka" = "" ] ; then
  nohup "$CURRENT_DIR"/background/springbootstarteurekaserver.sh &>/dev/null &
fi
while [ "$pIDeureka" = "" ]
  do
  sleep $sleeptime
  pIDeureka=`lsof -i :$porteureka|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDeureka &>/dev/null &
  echo -n "."
done
echo "eureka start success!"
echo "start configserver"

pIDconfig=`lsof -i :$portconfig|grep  "LISTEN" | awk '{print $2}'`
echo $pIDconfig 
if [ "$pIDconfig" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartconfigserver.sh &>/dev/null &
fi
while [ "$pIDconfig" = "" ]
  do
  sleep $sleeptime
  pIDconfig=`lsof -i :$portconfig|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDconfig &>/dev/null &
  echo -n "."
done
echo "springbootconfig start success!"
sleep 5
fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "1" ]; then
echo "start taskengine"
pIDtaskengine=`lsof -i :$porttaskengine|grep  "LISTEN" | awk '{print $2}'`
echo $pIDtaskengine
if [ "$pIDtaskengine" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstarttaskengine.sh &>/dev/null &
fi
while [ "$pIDtaskengine" = "" ]
  do
  sleep $sleeptime
  pIDtaskengine=`lsof -i :$porttaskengine|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDtaskengine &>/dev/null &
  echo -n "."
done
echo "taskengine start success!"

echo "start im-task-start"
pIimtask=`lsof -i :$portimtask|grep  "LISTEN" | awk '{print $2}'`
echo $pIimtask
if [ "$pIimtask" = "" ] ; then
nohup "$CURRENT_DIR"/im/im-task-start.sh &>/dev/null &
fi
echo "check im-task-start"
pIimtask=`lsof -i :$portimtask|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIimtask" = "" ]
  do
  sleep $sleeptime
  pIimtask=`lsof -i :$portimtask|grep  "LISTEN" | awk '{print $2}'`
  echo $pIimtask &>/dev/null &
  echo -n "."
done
echo "im-task-start success!"

echo "start activemqserver"
pIDactivemq=`lsof -i :$portactivemq|grep  "LISTEN" | awk '{print $2}'`
echo $pIDactivemq 
if [ "$pIDactivemq" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartactivemqserver.sh &>/dev/null &
sleep $sleeptime
fi

fi


if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "2" ]; then
echo "start messageserver"
pIDmessage=`lsof -i :$portmessage|grep  "LISTEN" | awk '{print $2}'`
echo $pIDmessage
if [ "$pIDmessage" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartmessage.sh &>/dev/null &
sleep $sleeptime
fi

echo "start i18nserver"
pIDi18nserver=`lsof -i :$porti18nserver|grep  "LISTEN" | awk '{print $2}'`
echo $pIDi18nserver
if [ "$pIDi18nserver" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstarti18nserver.sh &>/dev/null &
sleep $sleeptime
fi

echo "start cmdb"
pIDcmdb=`lsof -i :$portcmdb|grep  "LISTEN" | awk '{print $2}'`
echo $pIDcmdb
if [ "$pIDcmdb" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartcmdb.sh &>/dev/null &
sleep $sleeptime
fi

echo "start vspheremanage"
pIDvspheremanage=`lsof -i :$portvspheremanage|grep  "LISTEN" | awk '{print $2}'`
echo $pIDvspheremanage
if [ "$pIDvspheremanage" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartvspheremanage.sh &>/dev/null &
sleep $sleeptime
fi

fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "3" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "3" ]; then
echo "start alarmcenter"
pIDalarmcenter=`lsof -i :$portalarmcenter|grep  "LISTEN" | awk '{print $2}'`
echo $pIDalarmcenter
if [ "$pIDalarmcenter" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartalarmcenter.sh &>/dev/null &
sleep $sleeptime
fi

echo "start taskjob"
pIDtaskjob=`lsof -i :$porttaskjob|grep  "LISTEN" | awk '{print $2}'`
echo $pIDtaskjob
if [ "$pIDtaskjob" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartTaskjob.sh &>/dev/null &
sleep $sleeptime
fi

echo "start zuulmanager"
pIDzuulmanager=`lsof -i :$portzuulmanager|grep  "LISTEN" | awk '{print $2}'`
echo $pIDzuulmanager 
if [ "$pIDzuulmanager" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartzuulmanager.sh &>/dev/null &
sleep $sleeptime
fi

fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "4" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "4" ]; then

echo "start im-provider-start"
pIimprovider=`lsof -i :$portimprovider|grep  "LISTEN" | awk '{print $2}'`
echo $pIimprovider
if [ "$pIimprovider" = "" ] ; then
nohup "$CURRENT_DIR"/im/im-provider-start.sh &>/dev/null &
sleep $sleeptime
fi

echo "start im-3rdinf-start"
pI3rdinf=`lsof -i :$portim3rdinf|grep  "LISTEN" | awk '{print $2}'`
echo $pI3rdinf
if [ "$pI3rdinf" = "" ] ; then
nohup "$CURRENT_DIR"/im/im-3rdinf-start.sh &>/dev/null &
sleep $sleeptime
fi

echo "start servicemonitor"
pIDservicemonitor=`lsof -i :$portservicemonitor|grep  "LISTEN" | awk '{print $2}'`
echo $pIDservicemonitor
if [ "$pIDservicemonitor" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartservicemonitor.sh &>/dev/null &
sleep $sleeptime
fi
fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "5" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "5" ]; then
echo "start im-web-start"
pIimweb=`lsof -i :$portimweb|grep  "LISTEN" | awk '{print $2}'`
echo $pIimweb
if [ "$pIimweb" = "" ] ; then
nohup "$CURRENT_DIR"/im/im-web-start.sh &>/dev/null &
sleep $sleeptime
fi

echo "start esee-manager"
pIesee=`lsof -i :$porteseemanager|grep  "LISTEN" | awk '{print $2}'`
echo $pIesee
if [ "$pIesee" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstarteseemanager.sh &>/dev/null &
sleep $sleeptime
fi

echo "start gmcc-manager"
pIgmcc=`lsof -i :$portgmccmanager|grep  "LISTEN" | awk '{print $2}'`
echo $pIgmcc
if [ "$pIgmcc" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartgmccmanager.sh &>/dev/null &
sleep $sleeptime
fi

#echo "start uniview-manager"
#pIuniview=`lsof -i :$portuniviewmanager|grep  "LISTEN" | awk '{print $2}'`
#echo $pIuniview
#if [ "$pIuniview" = "" ] ; then
#nohup "$CURRENT_DIR"/background/springbootstartuniviewmanager.sh &>/dev/null &
#fi

fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "2" ] || [ "$nodetype" = "3" ]; then
echo "start gatherframe"
pIDgatherframe=`lsof -i :$portgatherframe|grep  "LISTEN" | awk '{print $2}'`
echo $pIDgatherframe
if [ "$pIDgatherframe" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartgatherframe.sh &>/dev/null &
sleep $sleeptime
fi

echo "start vsphereagent"
pIDvsphereagent=`lsof -i :$portvsphereagent|grep  "LISTEN" | awk '{print $2}'`
echo $pIDvsphereagent
if [ "$pIDvsphereagent" = "" ] ; then
nohup "$CURRENT_DIR"/background/springbootstartvsphereagent.sh &>/dev/null &
sleep $sleeptime
fi
fi
