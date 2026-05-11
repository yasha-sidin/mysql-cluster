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

var ROOT_PASSWORD = env("MYSQL_ROOT_PASSWORD", "RootPassw0rd!");
var CLUSTER_NAME = env("CLUSTER_NAME", "otusCluster");
var NODES = ["db1", "db2", "db3", "db4", "db5"];
var cluster = null;

for (var i = 0; i < NODES.length; i++) {
  try {
    shell.connect({
      scheme: "mysql",
      user: "root",
      password: ROOT_PASSWORD,
      host: NODES[i],
      port: 3306
    });
    cluster = dba.getCluster(CLUSTER_NAME);
    print("Connected through " + NODES[i] + ".");
    break;
  } catch (e) {
  }
}

if (cluster === null) {
  throw new Error("No reachable cluster member was found.");
}

print(JSON.stringify(cluster.status({ extended: 1 }), null, 2));

