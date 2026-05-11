DELETE FROM mysql_query_rules;
DELETE FROM mysql_group_replication_hostgroups;
DELETE FROM mysql_servers;
DELETE FROM mysql_users;

INSERT INTO mysql_servers(hostgroup_id, hostname, port, max_connections, weight, comment) VALUES
  (10, 'db1', 3306, 200, 100, 'cluster member'),
  (30, 'db2', 3306, 200, 100, 'cluster member'),
  (30, 'db3', 3306, 200, 100, 'cluster member'),
  (30, 'db4', 3306, 200, 1000, 'preferred reader'),
  (30, 'db5', 3306, 200, 100, 'preferred backup source');

INSERT INTO mysql_group_replication_hostgroups(
  writer_hostgroup,
  backup_writer_hostgroup,
  reader_hostgroup,
  offline_hostgroup,
  active,
  max_writers,
  writer_is_also_reader,
  max_transactions_behind,
  comment
) VALUES (10, 20, 30, 40, 1, 1, 0, 5, 'otusCluster');

INSERT INTO mysql_users(username, password, default_hostgroup, transaction_persistent, active) VALUES
  ('app', 'AppPassw0rd!', 10, 1, 1);

INSERT INTO mysql_query_rules(rule_id, active, match_digest, destination_hostgroup, apply, comment) VALUES
  (100, 1, '^SELECT.*FOR UPDATE', 10, 1, 'locking reads go to writer'),
  (110, 1, '^SELECT', 30, 1, 'regular reads go to readers');

UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='MonitorPassw0rd!' WHERE variable_name='mysql-monitor_password';
UPDATE global_variables SET variable_value='2000' WHERE variable_name='mysql-monitor_connect_interval';
UPDATE global_variables SET variable_value='2000' WHERE variable_name='mysql-monitor_ping_interval';
UPDATE global_variables SET variable_value='2000' WHERE variable_name='mysql-monitor_read_only_interval';
UPDATE global_variables SET variable_value='2000' WHERE variable_name='mysql-monitor_groupreplication_healthcheck_interval';

LOAD MYSQL VARIABLES TO RUNTIME;
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;

SAVE MYSQL VARIABLES TO DISK;
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
