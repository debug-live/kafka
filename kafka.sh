#!/usr/bin/env bash

curl http://mirrors.hust.edu.cn/apache/kafka/1.1.0/kafka_2.12-1.1.0.tgz | tar xz

cd kafka_2.12-1.1.0
bin/zookeeper-server-start.sh config/zookeeper.properties &

# Setting up a multi-broker cluster
cp config/server.properties config/server-1.properties
cp config/server.properties config/server-2.properties
sed -i -e 's/broker.id=0/broker.id=1/' -e 's/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/:9093/' -e 's/log.dirs=\/tmp\/kafka-logs/log.dirs=\/tmp\/kafka-logs-1/' config/server-1.properties
sed -i -e 's/broker.id=0/broker.id=2/' -e 's/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/:9094/' -e 's/log.dirs=\/tmp\/kafka-logs/log.dirs=\/tmp\/kafka-logs-2/' config/server-2.properties

bin/kafka-server-start.sh config/server.properties &
bin/kafka-server-start.sh config/server-1.properties &
bin/kafka-server-start.sh config/server-2.properties &

# Create a topic with a replication factor of three
bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic my-replicated-topic
bin/kafka-topics.sh --describe --zookeeper localhost:2181 --topic my-replicated-topic

# Public messages to the topic
echo hello > msg
echo world >> msg
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic my-replicated-topic < msg

# Consume the message
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --from-beginning --topic my-replicated-topic
