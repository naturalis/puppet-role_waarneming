# Install webserver and app
class role_waarneming::php_app (
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
  # Install and configure webserver
  include ::role_waarneming::web

  # Defaults for all file resources
  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Create user and place ssh key
  user { 'waarneming':
    ensure     => present,
    managehome => true,
  }
  
  file { '/home/waarneming/media':
    ensure  => link,
    target  => '/data/waarneming/media',
    require => User['waarneming'],
  }

  file { [ '/home/waarneming/temp', '/home/waarneming/temp/cache' ]:
    ensure  => directory,
    owner   => 'waarneming',
    group   => 'waarneming',
    mode    => '0755',
    require => User['waarneming'],
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

  # Create symlink to static content dir
  file { '/home/waarneming/www/fotonew':
    ensure  => link,
    target  => '/home/waarneming/media/fotonew',
    require => Vcsrepo['/home/waarneming/www'],
  }

  # Place missing favicon
  file { '/home/waarneming/www/favicon.ico':
    ensure  => present,
    source  => 'puppet:///modules/role_waarneming/acc_favicon.ico',
    require => Vcsrepo['/home/waarneming/www'],
  }

  # Install required PHP packages
  $php_packages = [
    'php7.0-fpm', 'php-memcached', 'php7.0-curl', 'php7.0-gd', 'php7.0-pgsql', 'php7.0-intl', 'php7.0-mbstring', 'php7.0-xml', 'php7.0-zip', 'php-redis'
  ]
  package { $php_packages:
    ensure  => present,
    require => [
      Class['apt::update'],
    ],
  }

  # Configure and run fpm service
  file { '/etc/php/7.0/fpm/php.ini':
    ensure  => present,
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
  # disabled while copying vhost config files verbatim
  #create_resources('::role_waarneming::vhost', $sites)
}
