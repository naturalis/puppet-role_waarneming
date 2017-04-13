# == Class role_waarneming::phppgadmin
#
class role_waarneming::phppgadmin (
  $path     = '/srv/phppgadmin',
  $user     = 'www-data',
  $servers  = [],
  $revision = 'origin/REL_5-1',
) {

  file { $path:
    ensure => directory,
    owner  => $user,
  } ->

  vcsrepo { $path:
    ensure   => present,
    provider => git,
    source   => 'git://github.com/phppgadmin/phppgadmin.git',
    user     => $user,
    revision => $revision,
  }

  package { 'php' :
    ensure => present,
  }

  package { 'php7.0-pgsql' :
    ensure => present,
  }
  
  class { 'nginx': }

  nginx::resource::server { 'phppgadmin':
    www_root             => '/srv/phppgadmin',
    use_default_location => false
  }

  nginx::resource::location { "phppgadmin":
    ensure              => present,
    server              => 'phppgadmin',
    www_root            => '/srv/phppgadmin',
    location            => '~ \.php$',
    location_cfg_append => {
      'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
      'fastcgi_param'           => 'SCRIPT_FILENAME $document_root/$fastcgi_script_name',
      'fastcgi_pass'            => '127.0.0.1:9000',
      'fastcgi_index'           => 'index.php',
      'include'                 => 'fastcgi_params'
    },
    notify              => Class['nginx::service'],
  }

  file_line{'phppgadmin_conf_file_host':
    path    => '/srv/phppgadmin/conf/config.inc.php',
    match   => "\\t\\\$conf\\['servers'\\]\\[0\\]\\['host'\\] = '.*';$",
    line    => "\t\$conf['servers'][0]['host'] = '${role_waarneming::conf::db_host}';",
    require => Vcsrepo[$path],
  }

}
