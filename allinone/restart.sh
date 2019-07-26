#restart contrail services
sudo systemctl restart contrail@api
sudo systemctl restart contrail@schema
sudo systemctl restart contrail@svc-monitor
sudo systemctl restart contrail@control
sudo systemctl restart contrail@analytics-api
sudo systemctl restart contrail@collector
sudo systemctl restart contrail@query-engine


#stop contrail services
sudo systemctl stop contrail@api
sudo systemctl stop contrail@schema
sudo systemctl stop contrail@svc-monitor
sudo systemctl stop contrail@control
sudo systemctl stop contrail@analytics-api
sudo systemctl stop contrail@collector
sudo systemctl stop contrail@query-engine


#start contrail services
sudo systemctl start contrail@api
sudo systemctl start contrail@schema
sudo systemctl start contrail@svc-monitor
sudo systemctl start contrail@control
sudo systemctl start contrail@analytics-api
sudo systemctl start contrail@collector
sudo systemctl start contrail@query-engine


# infra services
sudo service redis-server start
sudo service zookeeper stop
sudo service rabbitmq-server stop
sudo service cassandra stop
