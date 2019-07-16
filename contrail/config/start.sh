# check the infra services
sudo service cassandra status
sudo service redis-server status
sudo service rabitmq status
sudo service redis-server status


# start the services
contrail-api --conf_file /etc/contrail/contrail-api.conf &
contrail-schema --conf_file /etc/contrail/contrail-schema-transformer.conf &
contrail-svc-monitor --conf_file /etc/contrail/contrail-svc-monitor.conf &
contrail-control --conf_file /etc/contrail/contrail-control.conf &
contrail-analytics-api --conf_file /etc/contrail/contrail-analytics-api.conf &
contrail-collector --conf_file /etc/contrail/contrail-collector.conf &
contrail-query-engine  --conf_file /etc/contrail/contrail-query-engine.conf &