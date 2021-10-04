require 'ruby-terraform'
require 'aws-sdk-ssm'
require 'faraday'
require 'faraday_middleware'
require 'json'

# Create AWS ssm client
ssm = Aws::SSM::Client.new(region: 'us-east-1')

puts "Building AWS Environment"

RubyTerraform::Commands::Init.new.execute(
    chdir: '../terraform')

RubyTerraform.apply(
    chdir: '../terraform',
    auto_approve: true
)

instance_ip = RubyTerraform::Commands::Output.new.execute(
    chdir: '../terraform',
    name: 'instance_public_ip'
)

instance_ip.gsub!(/\A"|"\Z/, '')

instance_id = RubyTerraform::Commands::Output.new.execute(
    chdir: '../terraform',
    name: 'instance_id'
)

instance_id.gsub!(/\A"|"\Z/, '')

puts
puts "AWS environment complete. Waiting for instance to become ready."

sleep(60)

puts
puts "Configuring instance"

curl_cmd = 'curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz'


# Send commands to config system
ssm.send_command({
    instance_ids: [instance_id],
    document_name:  "AWS-RunShellScript",
    timeout_seconds: 30,
    parameters: {
      "commands" => [curl_cmd, "echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-arptables", "echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-ip6tables", "echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables", "mkdir -p /opt/cni/bin", "tar -C /opt/cni/bin -xzf cni-plugins.tgz"]
      }
  })

puts
puts "Installing software"

# Send commands to install software
ssm.send_command({
instance_ids: [instance_id],
document_name:  "AWS-RunShellScript",
timeout_seconds: 300,
parameters: {
    "commands" => ["curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -", 'sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"', "sudo apt-get update && sudo apt-get -y install nomad", "sudo apt-get -y install consul", "sudo apt-get -y install apt-transport-https ca-certificates gnupg lsb-release", "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg", 'echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null', "sudo apt-get update", "sudo apt-get -y install docker-ce docker-ce-cli containerd.io", "sleep 30", "sudo nomad agent -dev-connect -bind 0.0.0.0 &", "sudo consul agent -dev &"]
    }
})

sleep (120) 

puts
puts "Instance configuration complete. Sending Nomad job to cluster."

#Create http client
@conn = Faraday.new(:url => "http://#{instance_ip}:4646/") do |f|
    f.adapter Faraday.default_adapter
  end

#Read plan
payload = File.read(("payload.json"))

#Send job
response = @conn.post("/v1/jobs") do |req|
    req.body = payload
end

sleep (15)

puts
puts "Install complete. Test with the following command:"
p "curl -X POST -H 'Authorization: mytoken' http://#{instance_ip}:5000/jobs"
