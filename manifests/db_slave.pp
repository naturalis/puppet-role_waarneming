# Install and configure PostgreSQL as slave
class role_waarneming::db_slave (
  $config_entries = {
    'max_connections'      => {value => 150},
    'hot_standby'          => {value => 'on'},
    'hot_standby_feedback' => {value => 'on'},
    'max_worker_processes' => {value => 16},
    'log_timezone'         => {value => 'localtime'},
  },

) {
  # Install PostgreSQL
  class { '::postgresql::server':
    listen_addresses     => "localhost,${$::role_waarneming::conf::db_slave_naturalis}",
    manage_recovery_conf => true,
    timezone             => 'localtime',
    require              => Class['postgresql::globals']
  }

  class { '::postgresql::server::postgis': }

  # Multiple configuration setting based on previous production setup
  create_resources('::postgresql::server::config_entry', $config_entries)

  $db_host = $::role_waarneming::conf::db_host
  $slavepw = $::role_waarneming::conf::async_slave_password

  ::postgresql::server::recovery { 'Create a recovery.conf file':
    standby_mode     => 'on',
    primary_conninfo => "host=${db_host} port=5432 user=async_slave password=${slavepw} application_name=async_slave",
  }
}
