INSTANCE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
ACL_TOKEN=

## Install repos
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"


## Install Packages
apt update && apt install -y unzip consul docker.io jq dnsmasq

## Configure Consul Client
cat <<EOT >> /etc/consul.d/consul.hcl
datacenter = "dc1"
data_dir = "/opt/consul"

client_addr = "0.0.0.0"

ui_config{
  enabled = true
}

bind_addr = "0.0.0.0" # Listen on all IPv4
#
advertise_addr = "$${INSTANCE_IP}"

retry_join = ["<consul_server_0>", "<consul_server_1>", "<consul_server_2>"]

encrypt="7QS2BDss0XKa6HMCioyPp7wNiTAVAsbpkuNo3ZlAWt0="

verify_incoming = false
verify_outgoing = true
verify_server_hostname = true
ca_file = "/etc/consul.d/consul-agent-ca.pem"
auto_encrypt = {
  tls = true
}

ports {
  serf_wan = -1
  grpc = 8502
}

connect {
  enabled = true
}

acl = {
  enabled = true
  down_policy = "async-cache"
  default_policy = "deny"
  enable_token_persistence = true
  tokens {
    agent = "$${ACL_TOKEN}"
  }
}
EOT

## INstall Envoy

wget wget https://github.com/envoyproxy/envoy/releases/download/v1.24.1/envoy-1.24.1-linux-x86_64
mv envoy-1.24.1-linux-x86_64 /usr/local/bin/envoy
chmod +x /usr/local/bin/envoy

cat <<EOT >> /etc/systemd/system/consul-envoy.service
[Unit]
Description=Consul Envoy
After=syslog.target network.target

[Service]
Environment=CONSUL_HTTP_TOKEN=$${ACL_TOKEN}
ExecStart=/usr/bin/consul connect envoy -sidecar-for legacy-service
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
EOT


## Get a fake service going
mkdir /opt/fake-service
wget https://github.com/nicholasjackson/fake-service/releases/download/v0.24.2/fake_service_linux_amd64.zip
unzip -d /opt/fake-service/ fake_service_linux_amd64.zip 

cat <<EOT >> /etc/systemd/system/legacy-service.service
[Unit]
Description=Fake Service
After=syslog.target network.target

[Service]
Environment=NAME="Legacy Service"
Environment=MESSAGE="I'm running on a VM"
ExecStart=/opt/fake-service/fake-service 
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
EOT

cat <<EOT >> /etc/consul.d/legacy-service.hcl
service {
  name = "legacy-service"
  port = 9090
  tags = ["vm", "legacy"]

  checks = [
    {
      name = "HTTP API on port 5000"
      http = "http://127.0.0.1:9090/health"     
      interval = "10s"
      timeout = "5s"
    }
  ]

  connect = {
    sidecar_service = {}
  }
  token = "$${ACL_TOKEN}"
}
