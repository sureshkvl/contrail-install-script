if [ $1 = "status" ] || [ $1 = "start" ] || [ $1 = "stop" ]
then
    sudo service redis-server $1
    sudo service zookeeper $1
    sudo service rabbitmq-server $1
    sudo service cassandra $1
else
   echo "Argument error.  status or start or stop allowed"
fi
