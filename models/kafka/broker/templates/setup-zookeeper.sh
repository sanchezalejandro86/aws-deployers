#!/bin/bash
# Packages
sudo apt-get update && \
      sudo apt-get -y install wget ca-certificates zip net-tools vim nano tar netcat

# Java Open JDK 8
sudo apt-get -y install default-jdk
java -version

# Disable RAM Swap - can set to 0 on certain Linux distro
sudo sysctl vm.swappiness=1
echo 'vm.swappiness=1' | sudo tee --append /etc/sysctl.conf

local_ip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

sudo tee /tmp/change_record_route53.json << END
{
  "Comment": "Asignar el DNS interno para el server zookeeper-kafka en cuestion",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "zookeeper${ami_launch_index}.local.${clustername}",
        "Type": "A",
        "TTL": 5,
        "ResourceRecords": [
          {
            "Value": "$local_ip"
          }
        ]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "kafka${ami_launch_index}.local.${clustername}",
        "Type": "A",
        "TTL": 5,
        "ResourceRecords": [
          {
            "Value": "$local_ip"
          }
        ]
      }
    }
  ]
}
END

sudo apt-get -y install python-pip
sudo apt-get -y install awscli
#pip install awscli

aws route53 change-resource-record-sets --hosted-zone-id ${hosted_zone_id} --change-batch file:///tmp/change_record_route53.json

# download Zookeeper and Kafka. Recommended is latest Kafka (0.10.2.1) and Scala 2.12
cd /home/ubuntu/
wget http://apache.mirror.digitalpacific.com.au/kafka/0.10.2.1/kafka_2.12-0.10.2.1.tgz
tar -xvzf kafka_2.12-0.10.2.1.tgz
rm kafka_2.12-0.10.2.1.tgz
mv kafka_2.12-0.10.2.1 kafka
cd kafka/

# Install Zookeeper boot scripts

#sudo tee /etc/init.d/zookeeper << END
#END
sudo curl https://s3.amazonaws.com/workia.com-config/zookeeper >> /etc/init.d/zookeeper 

sudo chmod +x /etc/init.d/zookeeper
sudo chown root:root /etc/init.d/zookeeper
# you can safely ignore the warning
sudo update-rc.d zookeeper defaults


# start zookeeper
sudo service zookeeper start

# create data dictionary for zookeeper
sudo mkdir -p /data/zookeeper
sudo chown -R ubuntu:ubuntu /data/
# declare the server's identity
echo ${ami_launch_index} > /data/zookeeper/myid
# edit the zookeeper settings
rm /home/ubuntu/kafka/config/zookeeper.properties
sudo tee /home/ubuntu/kafka/config/zookeeper.properties << END
# the location to store the in-memory database snapshots and, unless specified otherwise, the transaction log of updates to the database.
dataDir=/data/zookeeper
# the port at which the clients will connect
clientPort=2181
# disable the per-ip limit on the number of connections since this is a non-production config
maxClientCnxns=0
# the basic time unit in milliseconds used by ZooKeeper. It is used to do heartbeats and the minimum session timeout will be twice the tickTime.
tickTime=2000
# The number of ticks that the initial synchronization phase can take
initLimit=10
# The number of ticks that can pass between
# sending a request and getting an acknowledgement
syncLimit=5
# zoo servers
# these hostnames such as zookeeper1 come from the /etc/hosts file
server.1=zookeeper1.local.${clustername}:2888:3888
server.2=zookeeper2.local.${clustername}:2888:3888
server.3=zookeeper3.local.${clustername}:2888:3888
END

