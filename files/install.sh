# variables
my_ip6=$(ip addr show dev eth0 | grep inet6 | awk '{print $2}' | head -1 | cut -d/ -f1)
consul_domain="consul.YOUR-DOMAIN-NAME"

echo " ===> Updating package cache"
apt-get update

echo " ===> Installing unzip"
apt-get install -y unzip

echo " ===> Creating Consul user"
useradd -m -d /var/lib/consul -r consul

echo " ===> Creating Consul-related directories and files"
mkdir -p /var/lib/consul
chown consul: /var/lib/consul
chmod 750 /var/lib/consul

mkdir -p /etc/consul.d
chown consul: /etc/consul.d
chmod 750 /etc/consul.d

mkdir -p /opt/consul-web
chown consul: /opt/consul-web
chmod 750 /opt/consul-web

touch /var/log/consul.log
chown consul: /var/log/consul.log
chmod 640 /var/log/consul.log

echo " ===> Installing Consul"
if [[ ! -f /usr/local/bin/consul ]]; then
  pushd /tmp
    wget https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip
    unzip 0.5.2_linux_amd64.zip
    mv consul /usr/local/bin
  popd
fi

echo " ===> Installing Consul web interface"
if [[ ! -d /opt/consul-web/dist ]]; then
  pushd /tmp
    wget https://dl.bintray.com/mitchellh/consul/0.5.2_web_ui.zip
    unzip -d /opt/consul-web 0.5.2_web_ui.zip
    chown -R consul: /opt/consul-web
  popd
fi

for attempt in {1..10}; do
  _nodes=($(dig -t txt ${consul_domain} | grep TXT | awk '{print $5}' | grep -v ^$ | sort | tr -d \"))
  if [[ -z $_nodes ]]; then
    echo "No consul nodes found. Sleeping"
    sleep 60
  else
    break
  fi
done

_consul_nodes=""
for _node in "${_nodes[@]}"; do
  if [[ -z $_consul_nodes ]]; then
    _consul_nodes="\"${_node}\""
  else
    _consul_nodes="${_consul_nodes}, \"${_node}\""
  fi
done

echo " ===> Configuring Consul"
cat >/etc/consul.d/config.json <<EOF
{
    "advertise_addr": "${my_ip6}",
    "client_addr": "0.0.0.0",
    "bind_addr": "0.0.0.0",
    "bootstrap_expect": 3,
    "data_dir": "/var/lib/consul",
    "datacenter": "honolulu",
    "encrypt": "Igap4fQTve7zt93XJ9lVQw==",
    "rejoin_after_leave": true,
    "retry_interval": "30s",
    "retry_join": [
        ${_consul_nodes}
    ],
    "server": true,
    "enable_syslog": true,
    "log_level": "INFO",
    "ui_dir": "/opt/consul-web/dist"
}
EOF

echo " ===> Installing init script"
cp /home/ubuntu/files/consul.conf /etc/init/

echo " ===> Starting Consul"
start consul
