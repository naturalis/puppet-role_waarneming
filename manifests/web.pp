# Install webserver and app
class waarneming::web (
  $sites = {
    'waarneming'    => {
      'ssl_key'     => $::waarneming::conf::waarneming_key,
      'ssl_crt'     => $::waarneming::conf::waarneming_crt,
      'server_name' => $::waarneming::conf::waarneming_server_name,
    },
    'observation'   => {
      'ssl_key'     => $::waarneming::conf::observation_key,
      'ssl_crt'     => $::waarneming::conf::observation_crt,
      'server_name' => $::waarneming::conf::observation_server_name,
    },
    'wnimg'         => {
      'ssl_key'     => $::waarneming::conf::wnimg_key,
      'ssl_crt'     => $::waarneming::conf::wnimg_crt,
      'server_name' => $::waarneming::conf::wnimg_server_name,
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

  # Add PHP 7.0 ppa
  ::apt::ppa { 'ppa:ondrej/php':
    ensure         => present,
    package_manage => true,
  }

  # Install required PHP packages 
  $php_packages = [
    'php7.0-fpm', 'php-memcached', 'php7.0-curl', 'php7.0-gd', 'php7.0-pgsql', 'php7.0-mbstring', 'php7.0-xml', 'php7.0-zip',
  ]
  package { $php_packages:
    ensure  => present,
    require => [
      Apt::Ppa['ppa:ondrej/php'],
      Class['apt::update'],
    ]
  }

  service { 'php7.0-fpm':
    ensure  => running,
    enable  => true,
    require => Package['php7.0-fpm'],
  }

  file { '/etc/php/7.0/fpm/php.ini':
    source  => 'puppet:///modules/waarneming/fpm/php.ini',
    notify  => Service['php7.0-fpm'],
    require => Package['php7.0-fpm'],
  }

  file { '/etc/php/7.0/fpm/pool.d/www.conf':
    source  => 'puppet:///modules/waarneming/fpm/www.conf',
    notify  => Service['php7.0-fpm'],
    require => Package['php7.0-fpm'],
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

  # nginx include files
  file { '/etc/nginx/include':
    source  => 'puppet:///modules/waarneming/nginx_include',
    recurse => true,
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  # Speciale defined resource totdat nginx module gefixt is
  create_resources('::waarneming::vhost', $sites)

  user { 'waarneming':
    ensure     => present,
    managehome => true,
  }
  
  # Check out bitbucket repo
  package { 'git':
    ensure => present,
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
    content => $::waarneming::conf::git_repo_key,
    require => File['/home/waarneming/.ssh'],
  }

  package { 'dnsutils':
    ensure => present,
  }

  exec { 'generate_known_hosts':
    command => 'dig +short -t A bitbucket.org | ssh-keyscan -f - bitbucket.org > /home/waarneming/.ssh/known_hosts',
    creates => '/home/waarneming/.ssh/known_hosts',
    user    => 'waarneming',
    path    => '/usr/bin',
    require => [
      File['/home/waarneming/.ssh'],
      Package['dnsutils'],
    ]
  }

  vcsrepo { '/home/waarneming/www':
    ensure   => latest,
    provider => git,
    source   => $::waarneming::conf::git_repo_url,
    user     => 'waarneming',
    require  => [
      File['/home/waarneming/.ssh/id_rsa'],
      Exec['generate_known_hosts'],
    ]
  }

  file { '/home/waarneming/www/_app/config.app.database.php':
    owner   => 'waarneming',
    group   => 'waarneming',
    content => template('waarneming/config.app.database.php.erb'),
    require => Vcsrepo['/home/waarneming/www'],
  }
}
