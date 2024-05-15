#! /bin/sh
yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo chkconfig docker on
docker info

sudo yum install git -y
git clone https://github.com/cryslam/quest.git
cd quest/
sudo docker build -t cryslam28/quest-app .
sudo docker run --name quest-app -p 80:3000 -d cryslam28/quest-app