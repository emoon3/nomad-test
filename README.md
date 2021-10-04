# nomad-test

Test deployment of Nomad server and client. Requires the following:

AWS cli
terraform
ruby
bundler

and the following env set for your AWS environment:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION


To deploy:

navigate to the terraform-ruby directory
execute the 'bundle' command
execute the 'ruby nomad-cluster-deploy.rb' command

The script should take about 4-5 minutes to finish.

The script will create an EC instance, a security group allowing the ports needed, and an instance role.

It will then install the necessary software on the instance and deploy the Nomad job via the Nomad API.