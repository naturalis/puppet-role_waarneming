# Install webserver and app
class role_waarneming::django_app (
  $sites = {
    'django' => {
      'ssl_key'     => $::role_waarneming::conf::observation_key,
      'ssl_crt'     => $::role_waarneming::conf::observation_crt,
      'server_name' => 'test-nl.observation.org test-be.observation.org',
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
  user { 'obs':
    ensure     => present,
    managehome => true,
  }
  
  file { '/home/obs/.ssh':
    ensure  => directory,
    owner   => 'obs',
    group   => 'obs',
    mode    => '0700',
    require => User['obs'],
  }

  file { '/home/obs/.ssh/id_rsa':
    owner   => 'obs',
    group   => 'obs',
    mode    => '0600',
    content => $::role_waarneming::conf::git_repo_key_django,
    require => File['/home/obs/.ssh'],
  }

  # Check out bitbucket repo
  vcsrepo { '/home/obs/django':
    ensure   => present,
    provider => git,
    source   => $::role_waarneming::conf::git_repo_url_django,
    revision => $::role_waarneming::conf::git_repo_rev_django,
    user     => 'obs',
    #notify   => Service['php7.0-fpm'],
    require  => [
      File['/home/obs/.ssh/id_rsa'],
      Sshkey['bitbucket_org_rsa'],
      Sshkey['bitbucket_org_dsa'],
    ]
  }

  # Configure postgres user credentials in app
  file { '/home/obs/django/app/settings_local.py':
    owner   => 'obs',
    group   => 'obs',
    content => template('role_waarneming/settings_local.py.erb'),
    require => Vcsrepo['/home/obs/django'],
  }

  # Install postgres python and dev libs
  class { '::postgresql::lib::python': }
  class { '::postgresql::lib::devel': }

  class { '::python':
    dev        => present,
    virtualenv => present,
  }->
  ::python::virtualenv { '/home/obs/virtualenv' :
    ensure       => present,
    requirements => '/home/obs/django/requirements.txt',
    owner        => 'obs',
    group        => 'obs',
    require      => [
      Vcsrepo['/home/obs/django'],
      Class['postgresql::lib::devel'],
    ],
  }

  # Special defined resource until config is cleaned up
  # and we can use build-in nginx module resources
  create_resources('::role_waarneming::vhost', $sites)
}
