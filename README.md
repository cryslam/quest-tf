# Quest Project IaC with Terraform

Preface: I requested public cert from ACM and next step is to associate it with my LoadBalancer to satisfy TLS - Step 7 in project requirements

* Set up data sources and terraform initialize
* Create IAM role, policy document, and IAM instance profile
* Used Terraform module for security groups
  * ssh, http, 443, and 3000 ingress rules (code shows grafana-tcp --> module had preset port 3000 which matched app port)
*  Create EC2 instance and Elastic IP to ensure public ip stays same (makes ssh'ing with key pair a lot easier)  
  * user-data shell script ensures docker, and git is installed && builds docker container and runs docker container 
*  Create LoadBalancer listening on port 80 HTTP and forward to target group attached to EC2 instance created above with health checks

Instructions:
**Note** Prerequisites are that you have aws cli, terraform, and docker installed on your local machine
1. clone this repository
2. cd into project folder
3. run `terraform init` to get all TF config files and set up working directory (and the modules used)
4. run `terraform validate` to ensure config files/ code references are correct
5. run `terraform plan` to ensure all resources being created is correct and the differences from previous state and now is correct
6. run `terraform apply` check if all is well then type in `yes` and hit return to update/ create new resources


