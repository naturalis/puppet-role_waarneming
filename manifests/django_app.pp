# Install webserver and app
class role_waarneming::django_app (
  $sites = {
    'django' => {
      'ssl_key'     => $::role_waarneming::conf::observation_key,
      'ssl_crt'     => $::role_waarneming::conf::observation_crt,
      'server_name' => 'test-nl.observation.org test-be.observation.org',
    },
  },

  $ssh_keys = {
    'obs_django'     => { user => 'obs', key => $::role_waarneming::conf::ssh_key_obs },
    'hugo_django'    => { user => 'obs', key => $::role_waarneming::conf::ssh_key_hugo },
    'dylan_django'   => { user => 'obs', key => $::role_waarneming::conf::ssh_key_dylan },
    'folkert_django' => { user => 'obs', key => $::role_waarneming::conf::ssh_key_folkert },
    'b1_django'      => { user => 'obs', key => $::role_waarneming::conf::ssh_key_b1 },
    'b2_django'      => { user => 'obs', key => $::role_waarneming::conf::ssh_key_b2 },
    'bt_django'      => { user => 'obs', key => $::role_waarneming::conf::ssh_key_bt },
    'bh_django'      => { user => 'obs', key => $::role_waarneming::conf::ssh_key_bh },
  }
) {
  # Install and configure webserver
  include ::role_waarneming::web

  # Defaults for all file resources
  File {
    ensure => present,
    owner  => 'obs',
    group  => 'obs',
    mode   => '0644',
  }

  # Defaults for all ssh authorized keys
  Ssh_Authorized_Key {
    ensure => present,
    type   => 'ssh-rsa',
  }

  # Create user and place ssh key
  user { 'obs':
    ensure     => present,
    uid        => '3000',
    gid        => '3000',
    groups     => ['waarneming'],
    managehome => true,
    shell      => '/bin/bash',
  }
  
  file {
    '/home/obs/.bashrc': source => 'puppet:///modules/role_waarneming/obs_bashrc';
    '/home/obs/.bash_profile': source => 'puppet:///modules/role_waarneming/obs_bash_profile';
  }

  file {
    '/home/obs/bin'                    : ensure => 'directory';
    '/home/obs/bin/flush_memcache.py'  : content => template('role_waarneming/obs_bin/flush_memcache.py.erb'), mode => '0755';
    '/home/obs/bin/remove_constraints' : content => template('role_waarneming/obs_bin/remove_constraints.erb'), mode => '0755';
    '/home/obs/bin/schema_cache'       : content => template('role_waarneming/obs_bin/schema_cache.erb'), mode => '0755';
  }

  file { '/home/obs/.ssh':
    ensure  => directory,
    mode    => '0700',
  }

  create_resources('ssh_authorized_key', $ssh_keys)

  # Place obs ssh key private and public parts
  file { '/home/obs/.ssh/id_rsa':
    mode    => '0600',
    content => $::role_waarneming::conf::git_repo_key_django,
    require => File['/home/obs/.ssh'],
  }

  ssh_authorized_key { 'obs@web':
    user    => 'obs',
    key     => $::role_waarneming::conf::ssh_key_obs,
    target  => '/home/obs/.ssh/id_rsa.pub',
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
    content => template('role_waarneming/settings_local.py.erb'),
    require => Vcsrepo['/home/obs/django'],
  }

  # Install postgres python and dev libs
  class { '::postgresql::lib::python': }
  class { '::postgresql::lib::devel': }

  # Install packages needed by django-app
  package { ['zlib1g-dev', 'libgdal1i']:
    ensure  => present,
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

  # Create uwsgi socket dir
  file { '/var/uwsgi':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0733',
    before => Exec['restart obs'],
  }

  file { '/etc/supervisor/conf.d/obs.conf':
    ensure  => present,
    owner  => 'root',
    group  => 'root',
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
