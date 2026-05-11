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

var SOURCE = env("BACKUP_SOURCE", "db5");
var TARGET = env("BACKUP_TARGET", "/backup-work/otus-backup");
var BACKUP_PASSWORD = env("MYSQL_BACKUP_PASSWORD", "BackupPassw0rd!");

shell.connect({
  scheme: "mysql",
  user: "backup",
  password: BACKUP_PASSWORD,
  host: SOURCE,
  port: 3306
});

util.dumpSchemas(["otus"], TARGET, {
  consistent: true,
  threads: 4,
  showProgress: true
});
