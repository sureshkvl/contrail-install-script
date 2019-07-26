if [ $1 = "status" ] || [ $1 = "start" ] || [ $1 = "stop" ]
then
    sudo systemctl $1 contrail@api
    sudo systemctl $1 contrail@schema
    sudo systemctl $1 contrail@svc-monitor
    sudo systemctl $1 contrail@control
    sudo systemctl $1 contrail@analytics-api
    sudo systemctl $1 contrail@query-engine
    sudo systemctl $1 contrail@collector    

else
   echo "Argument error.  status or start or stop allowed"
fi
