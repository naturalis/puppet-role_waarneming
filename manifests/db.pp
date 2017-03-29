# Install and configure PostgreSQL
class role_waarneming::db (
  $roles = {
    'waarneming'      => {
      'password_hash' => postgresql_password('waarneming', $::role_waarneming::conf::waarneming_password),
    },
    'local_be'        => {
      'password_hash' => postgresql_password('local_be', $::role_waarneming::conf::local_be_password),
    },
    'local_nl'        => {
      'password_hash' => postgresql_password('local_nl', $::role_waarneming::conf::local_nl_password),
    },
    'local_xx'        => {
      'password_hash' => postgresql_password('local_xx', $::role_waarneming::conf::local_xx_password),
    },
    'local_00'        => {
      'password_hash' => postgresql_password('local_00', $::role_waarneming::conf::local_00_password),
    },
    'hisko'           => {
      'superuser'     => true,
      'password_hash' => postgresql_password('hisko', $::role_waarneming::conf::hisko_password),
    },
    'hugo'            => {
      'superuser'     => true,
      'password_hash' => postgresql_password('hugo', $::role_waarneming::conf::hugo_password),
    },
    'obs'             => {
      'password_hash' => postgresql_password('obs', $::role_waarneming::conf::obs_password),
    },
    'obs_be'          => {
      'password_hash' => postgresql_password('obs', $::role_waarneming::conf::obs_be_password),
    },
    'analytics'       => {
      'superuser'     => true,
      'password_hash' => postgresql_password('analytics', $::role_waarneming::conf::analytics_password),
    },
  },
  $config_entries = {
    'max_connections'           => {value => 150},
    'shared_buffers'            => {value => '16GB'},
    'effective_cache_size'      => {value => '56GB'},
    'max_stack_depth'           => {value => '7680kB'},
    'temp_buffers'              => {value => '16MB'},
    'work_mem'                  => {value => '16MB'},
    'maintenance_work_mem'      => {value => '2GB'},
    'sort_mem'                  => {value => '64MB'},
    'random_page_cost'          => {value => 2},
    'track_activity_query_size' => {value => 8192},
    'shared_preload_libraries'  => {value => 'pg_stat_statements'},
    'pg_stat_statements.track'  => {value => 'all'}
  }
) {
  # Install PostgreSQL
  class { '::postgresql::server':
    listen_addresses => "localhost,${$::role_waarneming::conf::db_host}",
    require          => Class['postgresql::globals']
  }

  class { '::postgresql::server::postgis': }

  # Multiple performance enhancing tweaks based on previous production setup
  create_resources('::postgresql::server::config_entry', $config_entries)

  # Create postgresql database
  ::postgresql::server::database { $::role_waarneming::conf::db_name: }

  # Create postgresql users
  create_resources('::postgresql::server::role', $roles)

  # If conf::web_host is an IP (and not a hostname or CIDR range) add /32
  if (is_ip_address($::role_waarneming::conf::web_host)) and ($::role_waarneming::conf::web_host !~ /\d+\/\d{1,2}$/) {
    $web_host = "${$::role_waarneming::conf::web_host}/32"
  } else {
    $web_host = $::role_waarneming::conf::web_host
  }

  ::postgresql::server::pg_hba_rule { 'allow app host(s) to access database':
    description => "Open up PostgreSQL for access from ${$web_host}",
    type        => 'host',
    database    => 'all',
    user        => 'all',
    address     => $web_host,
    auth_method => 'md5',
    before      => Class['postgresql::server::reload']
  }

  # Postgres analytics scripts
  file { '/opt/postgresql':
    source  => 'puppet:///modules/role_waarneming/analytics',
    recurse => true,
  }
  
  # Jq for json magic
  package { 'jq':
    ensure => present,
  }

  # Generating postgres restore script
  file { '/usr/local/sbin/restore_db.sh':
    mode    => '0700',
    content => template('role_waarneming/restore_db.erb'),
  }

}
