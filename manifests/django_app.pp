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
    uid        => '3000',
    gid        => '3000',
    groups     => ['waarneming'],
    managehome => true,
  }
  
  file { '/home/obs/.ssh':
    ensure  => directory,
    owner   => 'obs',
    group   => 'obs',
    mode    => '0700',
    require => User['obs'],
  }

  ssh_authorized_key { 'obs_django':
    ensure => present,
    user   => 'obs',
    type   => 'ssh-rsa',
    key    => $::role_waarneming::conf::ssh_key_obs,
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
    ensure   => latest,
    provider => git,
    source   => $::role_waarneming::conf::git_repo_url_django,
    revision => $::role_waarneming::conf::git_repo_rev_django,
    user     => 'obs',
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

  # Install packages needed by django-app
  package { ['zlib1g-dev', 'libgdal1i']:
    ensure => present,
    require => Class['apt::update'],
  }

  # Install python, python-dev, virtualenv and create the virtualenv
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

  # Supervisord is used to manage the django UWSGI process
  package { 'supervisor':
    ensure  => present,
    require => Class['apt::update'],
  }

  service { 'supervisor':
    ensure  => running,
    require => Package['supervisor'],
  }

  file { '/etc/supervisor/conf.d/obs.conf':
    ensure  => present,
    source  => 'puppet:///modules/role_waarneming/supervisor_obs.conf',
    require => Package['supervisor'],
    notify  => Service['supervisor'],
  }

  # Run migrate to update DB schema
  exec { 'migrate obs':
    command     => 'python manage.py migrate --noinput',
    path        => '/home/obs/virtualenv/bin/',
    cwd         => '/home/obs/django',
    user        => 'obs',
    require     => [
      File['/home/obs/django/app/settings_local.py'],
      Python::Virtualenv['/home/obs/virtualenv'],
    ],
    before      => Exec['restart obs'],
    subscribe   => Vcsrepo['/home/obs/django'],
    refreshonly => true,
    timeout     => 0,
  }

  exec { 'collectstatic obs':
    command     => 'python manage.py collectstatic --noinput',
    path        => '/home/obs/virtualenv/bin/',
    cwd         => '/home/obs/django',
    user        => 'obs',
    require     => [
      File['/home/obs/django/app/settings_local.py'],
      Python::Virtualenv['/home/obs/virtualenv'],
    ],
    before      => Exec['restart obs'],
    subscribe   => Vcsrepo['/home/obs/django'],
    refreshonly => true,
    timeout     => 0,
  }

  exec { 'restart obs':
    command     => '/usr/bin/supervisorctl restart obs',
    require     => File['/etc/supervisor/conf.d/obs.conf'],
    subscribe   => Vcsrepo['/home/obs/django'],
    refreshonly => true,
  }

  # Special defined resource until config is cleaned up
  # and we can use build-in nginx module resources
  # disabled while copying vhost config files verbatim
  #create_resources('::role_waarneming::vhost', $sites)
}
