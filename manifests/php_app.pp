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
  },

  $ssh_keys = {
    'waarneming_php' => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_waarneming },
    'hugo_php'       => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_hugo },
    'dylan_php'      => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_dylan },
    'hisko_php'      => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_hisko },
    'sjaak_php'      => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_sjaak },
    'b1_php'         => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_b1 },
    'b2_php'         => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_b2 },
    'bt_php'         => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_bt },
    'bh_php'         => { user => 'waarneming', key => $::role_waarneming::conf::ssh_key_bh },
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

  # Defaults for all ssh authorized keys
  Ssh_Authorized_Key {
    ensure => present,
    type   => 'ssh-rsa',
  }

  # Create user and place ssh key and git config
  user { 'waarneming':
    ensure     => present,
    uid        => '3107',
    gid        => '3107',
    groups     => 'obs',
    managehome => true,
    shell      => '/bin/bash',
  }
  
  # Create /home/waarneming/temp dir structure
  $tmpdir = '/home/waarneming/temp'
  $temp_dirs = [
    $tmpdir, "${tmpdir}/cache",
    "${tmpdir}/export", "${tmpdir}/export/files",
    "${tmpdir}/lockfiles", "${tmpdir}/log", "${tmpdir}/ndff",
    "${tmpdir}/obsmapp", "${tmpdir}/obsmapp/temp", "${tmpdir}/obsmapp/upload",
    "${tmpdir}/scripts", "${tmpdir}/tmp"
  ]

  file { $temp_dirs:
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

  create_resources('ssh_authorized_key', $ssh_keys)

  # Place obs ssh key private and public parts
  file { '/home/waarneming/.ssh/id_rsa':
    owner   => 'waarneming',
    group   => 'waarneming',
    mode    => '0600',
    content => $::role_waarneming::conf::git_repo_key_php,
    require => File['/home/waarneming/.ssh'],
  }

  ssh_authorized_key { 'waarneming@web':
    user    => 'waarneming',
    key     => $::role_waarneming::conf::ssh_key_waarneming,
    target  => '/home/waarneming/.ssh/id_rsa.pub',
    require => File['/home/waarneming/.ssh'],
  }

  git::config { 'receive.denyCurrentBranch':
    value => 'ignore',
    user  => 'waarneming',
  }

  file { '/home/waarneming/media':
    ensure  => link,
    target  => '/data/waarneming/media',
    require => User['waarneming'],
  }

  # Check out php app repo
  vcsrepo { '/home/waarneming/www':
    ensure   => $::role_waarneming::conf::git_repo_ensure_php,
    provider => git,
    source   => $::role_waarneming::conf::git_repo_url_php,
    revision => $::role_waarneming::conf::git_repo_rev_php,
    user     => 'waarneming',
    notify   => Service['php7.2-fpm'],
    require  => [
      File['/home/waarneming/.ssh/id_rsa'],
      Sshkey['bitbucket_org_rsa'],
      Sshkey['bitbucket_org_dsa'],
    ]
  }

  # Symlink scripts
  file { '/home/waarneming/scripts':
    ensure => 'link',
    target => '/home/waarneming/www/_scripts',
    owner   => 'waarneming',
    group   => 'waarneming',
    require => [User['waarneming'],Vcsrepo['/home/waarneming/www']]
  }

  # Create config file used by the scripts
  file { '/home/waarneming/www/_scripts/_settings_local.sh':
    content => template('role_waarneming/_settings_local.sh.erb'),
    replace => $::role_waarneming::conf::php_managesettings,
    owner   => 'waarneming',
    group   => 'waarneming',
    require => File['/home/waarneming/scripts'],
  }

  # Create settings.php
  file { '/home/waarneming/www/_app/settings.php':
    content => template('role_waarneming/settings.php.erb'),
    replace => $::role_waarneming::conf::obs_managesettings,
    owner   => 'waarneming',
    group   => 'waarneming',
    require => [User['waarneming'],Vcsrepo['/home/waarneming/www']]
  }

  # Configure postgres use credentials in app
  file { '/home/waarneming/www/_app/config.app.database.php':
    content => template('role_waarneming/config.app.database.php.erb'),
    replace => $::role_waarneming::conf::obs_managesettings,
    owner   => 'waarneming',
    group   => 'waarneming',
    require => Vcsrepo['/home/waarneming/www'],
  }

  # Install required PHP packages
   apt::key { 'ondrej':
    id      => '14AA40EC0831756756D7F66C4F4EA0AAE5267A6C',
    server  => 'pgp.mit.edu',
    notify  => Exec['apt_update']
  }

  ::apt::ppa { 'ppa:ondrej/php': }

  $php_packages = [
    'php7.2-fpm',
    'php7.2-curl',
    'php7.2-gd',
    'php7.2-pgsql',
    'php7.2-intl',
    'php7.2-mbstring',
    'php7.2-xml',
    'php7.2-zip',
    'php-amqp',
    'php-memcached',
    'php-redis',
  ]
  package { $php_packages:
    ensure  => present,
    require => [Class['apt::update'],Apt::Ppa['ppa:ondrej/php'],Apt::Key['ondrej'],Package[$remove_php_packages]]
  }

  #remove php 7.0 
  $remove_php_packages = [
    'php7.0-fpm',
  ]
  package { $remove_php_packages:
    ensure  => absent,
    require => [Class['apt::update'],Apt::Ppa['ppa:ondrej/php'],Apt::Key['ondrej']]
  }


  # Configure and run fpm service
  file { '/etc/php/7.2/fpm/php.ini':
    ensure  => present,
    content => template('role_waarneming/php.ini.erb'),
    notify  => Service['php7.2-fpm'],
    require => Package['php7.2-fpm'],
  }

  file { '/etc/php/7.2/fpm/pool.d/www.conf':
    source  => 'puppet:///modules/role_waarneming/fpm/www.conf',
    notify  => Service['php7.2-fpm'],
    require => Package['php7.2-fpm'],
  }

  service { 'php7.2-fpm':
    ensure  => running,
    enable  => true,
    require => [
      Package['php7.2-fpm'],
      Class['redis'],
      Package[$remove_php_packages]
    ],
  }

  # Special defined resource until config is cleaned up
  # and we can use build-in nginx module resources
  # disabled while copying vhost config files verbatim
  #create_resources('::role_waarneming::vhost', $sites)
}
