# Quest Project IaC with Terraform

Preface: I requested public cert from ACM and next step is to associate it with my LoadBalancer to satisfy TLS - Step 7 in project requirements

### If give more time for Infrastructure, I would improve: ###
  *  Create ASG if we need to scale horizontally and have a min of instances for this application
  *  If the webapp were to grow with content, assets, and have customers worldwide -- CloudFront distribution could be an option
    *  Cloudfront due to edge locations esp if customers worldwide
    *  Can have WAF (web application firewall) in front of it to prevent layer 7 attacks like DDOS (distributed denial of service) or custom error pages
  *  enable logging and permissions for certain resources without wildcard * in policy to ensure transparency with monitoring, logging, and alerting (observability)
  *  ECR is also another service to leverage to host the images somewhere, and can add policy for ec2 to pull down image
  *  Given I only created 1 instance with lb sitting in front -- if web app scales it will need to be optimized vertically for instance type (cpu, mem, disk, etc) so you can always install CW agent to view other metrics and rightsize ec2 instance (also ensure cloud cost is minimal)

### My thoughtprocess and steps to create infra for Quest Project: ###
* Set up data sources and terraform initialize
* Create IAM role, policy document, and IAM instance profile
* Used Terraform module for security groups
  * ssh, http, 443, and 3000 ingress rules (code shows grafana-tcp --> module had preset port 3000 which matched app port)
*  Create EC2 instance and Elastic IP to ensure public ip stays same (makes ssh'ing with key pair a lot easier)  
  * user-data shell script ensures docker, and git is installed && builds docker container and runs docker container 
*  Create LoadBalancer listening on port 80 HTTP and forward to target group attached to EC2 instance created above with health checks

### Instructions: ###
**Note** Prerequisites are that you have aws cli, terraform, and docker installed on your local machine
1. clone this repository
2. cd into project folder
3. run `terraform init` to get all TF config files and set up working directory (and the modules used)
4. run `terraform validate` to ensure config files/ code references are correct
5. run `terraform plan` to ensure all resources being created is correct and the differences from previous state and now is correct
6. run `terraform apply` check if all is well then type in `yes` and hit return to update/ create new resources


