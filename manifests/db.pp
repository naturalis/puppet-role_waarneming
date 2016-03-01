# Install and configure PostgreSQL
class waarneming::db (
  $roles = {
    'waarneming'      => {
      'superuser'     => true,
      'password_hash' => postgresql_password('waarneming', $::waarneming::conf::waarneming_password),
    },
    'local_be'        => {
      'superuser'     => true,
      'password_hash' => postgresql_password('local_be', $::waarneming::conf::local_be_password),
    },
    'local_nl'        => {
      'superuser'     => true,
      'password_hash' => postgresql_password('local_nl', $::waarneming::conf::local_nl_password),
    },
    'local_xx'        => {
      'superuser'     => true,
      'password_hash' => postgresql_password('local_xx', $::waarneming::conf::local_xx_password),
    },
  }
) {
  # Install PostgreSQL
  class { '::postgresql::globals':
    manage_package_repo => true,
    version             => $::waarneming::conf::postgresql_version,
  }->
  class { '::postgresql::server': }

  # Create postgresql database
  ::postgresql::server::database { $::waarneming::conf::postgresql_dbname:
    require  => Class['postgresql::server'],
  }

  # Create postgresql users
  create_resources('::postgresql::server::role', $roles)
}

