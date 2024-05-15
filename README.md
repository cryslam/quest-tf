# Quest Project IaC with Terraform

Preface: I requested public cert from ACM and next step is to associate it with my LoadBalancer to satisfy TLS - Step 7 in project requirements

* Set up data sources and terraform initialize
* Create IAM role, policy document, and IAM instance profile
* Used Terraform module for security groups
  * ssh, http, 443, and 3000 ingress rules (code shows grafana-tcp --> module had preset port 3000 which matched app port)
*  Create EC2 instance and Elastic IP to ensure public ip stays same (makes ssh'ing with key pair a lot easier)  
  * user-data shell script ensures docker, and git is installed && builds docker container and runs docker container 
*  Create LoadBalancer listening on port 80 HTTP and forward to target group attached to EC2 instance created above with health checks
