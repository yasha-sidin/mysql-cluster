function env(name, fallback) {
  try {
    var value = os.getenv(name);
    if (value !== undefined && value !== null && value !== "") {
      return value;
    }
  } catch (e) {
  }
  return fallback;
}

function quote(value) {
  return "'" + String(value).replace(/\\/g, "\\\\").replace(/'/g, "''") + "'";
}

var ROOT_PASSWORD = env("MYSQL_ROOT_PASSWORD", "RootPassw0rd!");
var APP_PASSWORD = env("MYSQL_APP_PASSWORD", "AppPassw0rd!");
var MONITOR_PASSWORD = env("MYSQL_MONITOR_PASSWORD", "MonitorPassw0rd!");
var BACKUP_PASSWORD = env("MYSQL_BACKUP_PASSWORD", "BackupPassw0rd!");
var CLUSTER_NAME = env("CLUSTER_NAME", "otusCluster");
var IP_ALLOWLIST = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,127.0.0.1/8";
var NODES = ["db1", "db2", "db3", "db4", "db5"];

function connectRoot(host) {
  shell.connect({
    scheme: "mysql",
    user: "root",
    password: ROOT_PASSWORD,
    host: host,
    port: 3306
  });
}

function instanceDef(host) {
  return {
    user: "root",
    password: ROOT_PASSWORD,
    host: host,
    port: 3306
  };
}

connectRoot("db1");

var cluster;
try {
  cluster = dba.getCluster(CLUSTER_NAME);
  print("Cluster " + CLUSTER_NAME + " already exists.");
} catch (e) {
  print("Creating cluster " + CLUSTER_NAME + " on db1.");
  cluster = dba.createCluster(CLUSTER_NAME, {
    communicationStack: "XCOM",
    groupName: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    memberSslMode: "DISABLED",
    ipAllowlist: IP_ALLOWLIST,
    localAddress: "db1:33061"
  });
}

for (var i = 1; i < NODES.length; i++) {
  var host = NODES[i];
  var instanceAddress = host + ":3306";
  var clusterStatus = cluster.status();

  if (clusterStatus.defaultReplicaSet.topology.hasOwnProperty(instanceAddress)) {
    print(host + " is already registered in the cluster.");
    continue;
  }

  try {
    print("Adding " + host + " to the cluster.");
    cluster.addInstance(instanceDef(host), {
      recoveryMethod: "clone",
      recoveryProgress: 2,
      ipAllowlist: IP_ALLOWLIST,
      localAddress: host + ":33061"
    });
  } catch (e) {
    var message = String(e.message || e);
    if (message.indexOf("already") >= 0 || message.indexOf("Metadata") >= 0 || message.indexOf("member of a cluster") >= 0) {
      print(host + " is already registered in the cluster.");
    } else {
      print("Trying to rejoin " + host + ".");
      try {
        cluster.rejoinInstance(instanceDef(host), { ipAllowlist: IP_ALLOWLIST });
      } catch (rejoinError) {
        print("Failed to add or rejoin " + host + ": " + String(rejoinError.message || rejoinError));
        throw e;
      }
    }
  }
}

var status = cluster.status();
var primaryAddress = status.defaultReplicaSet.primary;
var primaryHost = primaryAddress.split(":")[0];
connectRoot(primaryHost);

session.runSql("CREATE DATABASE IF NOT EXISTS otus");

session.runSql("CREATE USER IF NOT EXISTS 'app'@'%' IDENTIFIED BY " + quote(APP_PASSWORD));
session.runSql("ALTER USER 'app'@'%' IDENTIFIED BY " + quote(APP_PASSWORD));
session.runSql("GRANT ALL PRIVILEGES ON otus.* TO 'app'@'%'");

session.runSql("CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED BY " + quote(MONITOR_PASSWORD));
session.runSql("ALTER USER 'monitor'@'%' IDENTIFIED BY " + quote(MONITOR_PASSWORD));
session.runSql("GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%'");
session.runSql("GRANT SELECT ON performance_schema.* TO 'monitor'@'%'");

session.runSql("CREATE USER IF NOT EXISTS 'backup'@'%' IDENTIFIED BY " + quote(BACKUP_PASSWORD));
session.runSql("ALTER USER 'backup'@'%' IDENTIFIED BY " + quote(BACKUP_PASSWORD));
session.runSql("GRANT EVENT, RELOAD, SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, REPLICATION CLIENT, BACKUP_ADMIN ON *.* TO 'backup'@'%'");

session.runSql("FLUSH PRIVILEGES");

cluster = dba.getCluster(CLUSTER_NAME);
print(JSON.stringify(cluster.status({ extended: 1 }), null, 2));
