# Install and configure PgBouncer
class role_waarneming::pgbouncer (
) {
  # Install PostgreSQL client software
  class { '::postgresql::client':
    require => Class['postgresql::globals'],
  }->
  class { '::pgbouncer':
    config_params => {
      'listen_port' => $::role_waarneming::conf::pgbouncer_port,
      'admin_users' => 'hugo,hugoadmin,dylan,dylanadmin,hisko,hiskoadmin',
      'auth_type'   => 'md5',
    },
    userlist      => [
      {
        'user'     => 'waarneming',
        'password' => $::role_waarneming::conf::waarneming_password,
      },
      {
        'user'     => 'local_be',
        'password' => $::role_waarneming::conf::local_be_password,
      },
      {
        'user'     => 'local_nl',
        'password' => $::role_waarneming::conf::local_nl_password,
      },
      {
        'user'     => 'local_xx',
        'password' => $::role_waarneming::conf::local_xx_password,
      },
    ],
    databases     => [
      {
        'source_db' => $::role_waarneming::conf::db_name,
        'host'      => $::role_waarneming::conf::db_host,
        'dest_db'   => $::role_waarneming::conf::db_name,
      },
    ],
  }
}
