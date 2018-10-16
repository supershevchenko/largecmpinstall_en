#!/bin/bash

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "3" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "3" ]; then
/etc/init.d/keepalived restart
echo "keepalived start success!"
fi
