docker run -it --entrypoint cqlsh \
  -v ./connect-bundle-test_cluster.yaml:/connect-bundle-test_cluster.yaml:Z \
  scylladb/scylla-cqlsh:v6.0.6 \
  --cloudconf connect-bundle-test_cluster.yaml


#commands for cloud instance
CREATE KEYSPACE mykeyspace WITH replication = {'class': 'NetworkTopologyStrategy', 'us-east-1' : 3} AND durable_writes = true;

USE mykeyspace;

CREATE TABLE monkeySpecies (
species text PRIMARY KEY,
common_name text,
population varint,
average_size int);

INSERT INTO monkeySpecies (species, common_name, population, average_size) VALUES ('Saguinus niger', 'Black tamarin', 10000, 500);

SELECT * FROM monkeySpecies;


#commands for local instance

docker run --name scyllaU -d scylladb/scylla:4.5.0 --overprovisioned 1 --smp 1

docker exec -it scyllaU nodetool status

docker exec -it scyllaU cqlsh

CREATE KEYSPACE mykeyspace WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};

use mykeyspace; 

CREATE TABLE users ( user_id int, fname text, lname text, PRIMARY KEY((user_id))); 


#docker cluster
docker run --name Node_X -d scylladb/scylla:4.5.0 --overprovisioned 1 --smp 1
docker run --name Node_Y -d scylladb/scylla:4.5.0 --seeds="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' Node_X)" --overprovisioned 1 --smp 1
docker run --name Node_Z -d scylladb/scylla:4.5.0 --seeds="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' Node_X)" --overprovisioned 1 --smp 1

docker exec -it Node_Z nodetool status  #for checking status

Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns    Host ID                               Rack
UN  172.17.0.3  178.24 KB  256          ?       7a0420be-9876-4b2e-9ace-f1e2a966de5a  rack1
UN  172.17.0.2  103.23 KB  256          ?       70233cd9-0990-436b-92a6-76b371830e62  rack1
UN  172.17.0.4  174.52 KB  256          ?       7bfb236e-cf42-485a-adba-a974b15d3c8a  rack1

docker exec -it Node_Z cqlsh 

CREATE KEYSPACE mykeyspace WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy', 'replication_factor' : 3};

use mykeyspace; 

CREATE TABLE users ( user_id int, fname text, lname text, PRIMARY KEY((user_id))); 

insert into users(user_id, fname, lname) values (1, 'rick', 'sanchez'); 
insert into users(user_id, fname, lname) values (4, 'rust', 'cohle'); 

select * from users;

# read and write at different consistency levels
docker exec -it Node_Z cqlsh
use mykeyspace; 
CONSISTENCY QUORUM 
insert into users (user_id, fname, lname) values (7, 'eric', 'cartman');
CONSISTENCY ALL 
insert into users (user_id, fname, lname) values (8, 'lorne', 'malvo'); 

exit
docker stop Node_Y 
docker exec -it Node_Z nodetool status 
docker exec -it Node_Z cqlsh 
CONSISTENCY QUORUM 
use mykeyspace;
insert into users (user_id, fname, lname) values (9, 'avon', 'barksdale');  
select * from users; 
CONSISTENCY ALL 
insert into users (user_id, fname, lname) values (10, 'vm', 'varga');  #both will fail as number of available nodes are less than rf and cl all
select * from users; 
exit
docker stop Node_Z 
docker exec -it Node_X nodetool status 
docker exec -it Node_X cqlsh 
CONSISTENCY QUORUM
use mykeyspace; 
insert into users (user_id, fname, lname) values (11, 'morty', 'smith');  #both will fail as number of available nodes are less than rf and cl all
select * from users; 
CONSISTENCY ONE 
insert into users (user_id, fname, lname) values (12, 'marlo', 'stanfield');   
select * from users; 


#Architechture exercises
docker run --name scylla-node1 -d scylladb/scylla:5.1.0
docker run --name scylla-node2 -d scylladb/scylla:5.1.0 --seeds="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' scylla-node1)" 
docker run --name scylla-node3 -d scylladb/scylla:5.1.0 --seeds="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' scylla-node1)" 

docker exec -it scylla-node3 nodetool status 

docker exec -it scylla-node3 cqlsh 

CREATE KEYSPACE mykeyspace WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy', 'replication_factor' : 3};

use mykeyspace; 

DESCRIBE KEYSPACE mykeyspace;

CREATE TABLE users ( user_id int, fname text, lname text, PRIMARY KEY((user_id))); 

insert into users(user_id, fname, lname) values (1, 'rick', 'sanchez'); 
insert into users(user_id, fname, lname) values (4, 'rust', 'cohle'); 
select * from users;


docker exec -it scylla-node3 bash
./usr/lib/scylla/seastar-cpu-map.sh -n scylla

git clone https://github.com/scylladb/scylla-code-samples.git
cd scylla-code-samples/mms
docker-compose up -d
docker-compose -f docker-compose-dc2.yml up -d
docker exec -it scylla-node1 nodetool status

docker exec -it scylla-node2 cqlsh
CREATE KEYSPACE scyllaU WITH REPLICATION = {'class' : 'NetworkTopologyStrategy', 'DC1' : 3, 'DC2' : 2};
Use scyllaU;
DESCRIBE KEYSPACE

docker exec -it scylla-node1 nodetool ring
docker exec -it scylla-node1 nodetool describering scyllau



docker exec -it scylla-node2 cqlsh
use scyllaU;
consistency EACH_QUORUM;
CREATE TABLE users ( user_id int, fname text, lname text, PRIMARY KEY((user_id))); 
insert into users(user_id, fname, lname) values (1, 'rick', 'sanchez'); 
insert into users(user_id, fname, lname) values (4, 'rust', 'cohle'); 

docker-compose -f docker-compose-dc2.yml pause

docker exec -it scylla-node2 nodetool status
insert into users(user_id, fname, lname) values (8, 'lorne', 'malvo'); 
select * from users;
consistency LOCAL_QUORUM;
select * from users;
docker exec -it scylla-node1 nodetool statusgossip
docker exec -it scylla-node1 nodetool gossipinfo