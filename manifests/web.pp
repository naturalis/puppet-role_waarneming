# Install webserver and app
class role_waarneming::web (
  $sites = {
    'waarneming'    => {
      'ssl_key'     => $::role_waarneming::conf::waarneming_key,
      'ssl_crt'     => $::role_waarneming::conf::waarneming_crt,
      'server_name' => $::role_waarneming::conf::waarneming_server_name,
    },
    'observation'   => {
      'ssl_key'     => $::role_waarneming::conf::observation_key,
      'ssl_crt'     => $::role_waarneming::conf::observation_crt,
      'server_name' => $::role_waarneming::conf::observation_server_name,
    },
    'wnimg'         => {
      'ssl_key'     => $::role_waarneming::conf::wnimg_key,
      'ssl_crt'     => $::role_waarneming::conf::wnimg_crt,
      'server_name' => $::role_waarneming::conf::wnimg_server_name,
    },
  }
) {
  # Defaults for all file resources
  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Git is needed for both PHP and Django websites
  package { 'git':
    ensure => present,
  }

  # Add required keys to system-wide known_hosts
  sshkey { 'bitbucket_org_rsa':
    ensure       => present,
    host_aliases => 'bitbucket.org',
    type         => 'ssh-rsa',
    key          => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==',
  }

  sshkey { 'bitbucket_org_dsa':
    ensure       => present,
    host_aliases => 'bitbucket.org',
    type         => 'ssh-dss',
    key          => 'AAAAB3NzaC1kc3MAAACBAO53E7Kcxeak0luot3Z5ulOQJoLRBcnBQb0gpUfNL5rZW63fBubfXLbpZc2/GnHxRiFa2okTPvBULJZnjwXltyoRfjPICRLfH/ep3mZj6CVUyQgxES27CS1bEjMw8+S6hLlJF4dKqOIWH5+Ed+lo8ezzXbzcEj7R5h9xGgfY55HfAAAAFQDE/aqj+0sxv/ZRS3ArGxMHGYFebwAAAIEA6lZ68WgDMrR28iXIicJ7AnXPnZKzQK7xK68feKlYo9LcEkKTF3AZIE5nEvtn+ZYwZ5cKE3XKeU42aesAEAUxX9cUEzhi87q6PQagD6ZPcU89CCVlWsG8cKYCZ6VtMfcLU06grNfvl450KCHltWTaoBHdi9f8eFo3Gydg6JhyNJ8AAACAThcLJmru5QtpHo9wctg5jHKxv1BLPndKs3dVwAQwcd2sugoymGeH7IjBSFLqHsyl7XpDik4mH/YdkVwb1jAwA+JOu2gHpsSXLY22At+LKn6NHdL/qqbIf7ellnKXfEo+wz6DfGihaczY931WrjkEEsq1453/4BwQpAXrz2zbRSI=',
  }

  # Activate redis service
  class { '::redis': }

  # Activate memcached service
  class { 'memcached':
    max_memory => 1024,
    user       => 'memcache',
    listen_ip  => '127.0.0.1',
    pidfile    => false,
  }

  # Install nginx
  Anchor['nginx::begin']
  ->
  class { '::nginx::config':
    log_format => {
      custom => '$time_iso8601 $status $remote_addr $host "$request" "$http_referer" "$http_user_agent" $body_bytes_sent $bytes_sent $request_length $request_time',
    },
  }

  class { '::nginx': }

  # Nginx include files, verbatim
  file { '/etc/nginx/include':
    source  => 'puppet:///modules/role_waarneming/nginx_include',
    recurse => true,
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  # Create user and place ssh key
  user { 'waarneming':
    ensure     => present,
    managehome => true,
  }
  
  file { '/home/waarneming/.ssh':
    ensure  => directory,
    owner   => 'waarneming',
    group   => 'waarneming',
    mode    => '0700',
    require => User['waarneming'],
  }

  file { '/home/waarneming/.ssh/id_rsa':
    owner   => 'waarneming',
    group   => 'waarneming',
    mode    => '0600',
    content => $::role_waarneming::conf::git_repo_key_php,
    require => File['/home/waarneming/.ssh'],
  }

  # Check out bitbucket repo
  vcsrepo { '/home/waarneming/www':
    ensure   => present,
    provider => git,
    source   => $::role_waarneming::conf::git_repo_url_php,
    revision => $::role_waarneming::conf::git_repo_rev_php,
    user     => 'waarneming',
    notify   => Service['php7.0-fpm'],
    require  => [
      File['/home/waarneming/.ssh/id_rsa'],
      Sshkey['bitbucket_org_rsa'],
      Sshkey['bitbucket_org_dsa'],
    ]
  }

  # Configure postgres use credentials in app
  file { '/home/waarneming/www/_app/config.app.database.php':
    owner   => 'waarneming',
    group   => 'waarneming',
    content => template('role_waarneming/config.app.database.php.erb'),
    require => Vcsrepo['/home/waarneming/www'],
  }

  # Add PHP 7.0 ppa
  ::apt::ppa { 'ppa:ondrej/php':
    ensure         => present,
    package_manage => true,
  }

  ::apt::key { 'ppa:ondrej/php':
    id => '14AA40EC0831756756D7F66C4F4EA0AAE5267A6C',
  }

  # Install required PHP packages
  $php_packages = [
    'php7.0-fpm', 'php-memcached', 'php7.0-curl', 'php7.0-gd', 'php7.0-pgsql', 'php7.0-mbstring', 'php7.0-xml', 'php7.0-zip', 'php-redis'
  ]
  package { $php_packages:
    ensure  => present,
    require => [
      Apt::Ppa['ppa:ondrej/php'],
      Apt::Key['ppa:ondrej/php'],
      Class['apt::update'],
    ],
  }

  # Configure and run fpm service
  file { '/etc/php/7.0/fpm/php.ini':
    source  => 'puppet:///modules/role_waarneming/fpm/php.ini',
    notify  => Service['php7.0-fpm'],
    require => Package['php7.0-fpm'],
  }

  file { '/etc/php/7.0/fpm/pool.d/www.conf':
    source  => 'puppet:///modules/role_waarneming/fpm/www.conf',
    notify  => Service['php7.0-fpm'],
    require => Package['php7.0-fpm'],
  }

  service { 'php7.0-fpm':
    ensure  => running,
    enable  => true,
    require => [
      Package['php7.0-fpm'],
      Class['redis'],
    ],
  }

  # Special defined resource until config is cleaned up
  # and we can use build-in nginx module resources
  create_resources('::role_waarneming::vhost', $sites)
}
