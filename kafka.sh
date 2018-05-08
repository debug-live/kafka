#!/usr/bin/env bash

curl http://mirrors.hust.edu.cn/apache/kafka/1.1.0/kafka_2.12-1.1.0.tgz | tar xz -C /opt
echo "export KAFKA_HOME=/opt/kafka_2.12-1.1.0" >> /etc/profile
echo "export PATH=$PATH:\${KAFKA_HOME}/bin" >> /etc/profile 
source /etc/profile

zookeeper-server-start.sh ${KAFKA_HOME}/config/zookeeper.properties &

# Setting up a multi-broker cluster
cp ${KAFKA_HOME}/config/server.properties ${KAFKA_HOME}/config/server-1.properties
cp ${KAFKA_HOME}/config/server.properties ${KAFKA_HOME}/config/server-2.properties

sed -i -e 's/broker.id=0/broker.id=1/' \
       -e 's/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/:9093/' \
       -e 's/log.dirs=\/tmp\/kafka-logs/log.dirs=\/tmp\/kafka-logs-1/' \
       ${KAFKA_HOME}/config/server-1.properties

sed -i -e 's/broker.id=0/broker.id=2/' \
       -e 's/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/:9094/' \
       -e 's/log.dirs=\/tmp\/kafka-logs/log.dirs=\/tmp\/kafka-logs-2/' \
       ${KAFKA_HOME}/config/server-2.properties

kafka-server-start.sh ${KAFKA_HOME}/config/server.properties &
kafka-server-start.sh ${KAFKA_HOME}/config/server-1.properties &
kafka-server-start.sh ${KAFKA_HOME}/config/server-2.properties &

# Create a topic with a replication factor of three
kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic my-replicated-topic
kafka-topics.sh --describe --zookeeper localhost:2181 --topic my-replicated-topic

# Public messages to the topic
echo hello > msg
echo world >> msg
kafka-console-producer.sh --broker-list localhost:9092 --topic my-replicated-topic < msg

# Consume the message
kafka-console-consumer.sh --bootstrap-server localhost:9092 --from-beginning --topic my-replicated-topic
