# Install webserver and app
class role_waarneming::django_noordzee_app (
  $python_version = $::role_waarneming::conf::noordzee_python_version,
  $sites = {
    'django_noordzee' => {
      'ssl_key'     => $::role_waarneming::conf::observation_key,
      'ssl_crt'     => $::role_waarneming::conf::observation_crt,
      'server_name' => 'test-nl.observation.org test-be.observation.org',
    },
  },

  $ssh_keys = {
    'noordzee_django'     => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_noordzee },
    'hugo_django'    => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_hugo },
    'dylan_django'   => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_dylan },
    'folkert_django' => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_folkert },
    'jieter_django'  => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_jieter },
    'b1_django'      => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_b1 },
    'b2_django'      => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_b2 },
    'bt_django'      => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_bt },
    'bh_django'      => { user => 'noordzee', key => $::role_waarneming::conf::ssh_key_bh },
  }
) {
  # Install and configure webserver
  include ::role_waarneming::web

  # Defaults for all file resources
  File {
    ensure => present,
    owner  => 'noordzee',
    group  => 'noordzee',
    mode   => '0644',
  }

  # Defaults for all ssh authorized keys
  Ssh_Authorized_Key {
    ensure => present,
    type   => 'ssh-rsa',
  }

  # Create user and place ssh key
  user { 'noordzee':
    ensure     => present,
    uid        => '3010',
    gid        => '3010',
    groups     => ['waarneming'],
    managehome => true,
    shell      => '/bin/bash',
  }

  # Add entries to sudoers. noordzee user can restart services. 
  augeas { "sudorestartnoordzee":
    context => "/files/etc/sudoers",
    changes => [
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/name SERVICES",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[1] '/usr/bin/supervisorctl start noordzee'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[2] '/usr/bin/supervisorctl stop noordzee'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[3] '/usr/bin/supervisorctl restart noordzee'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[4] '/usr/bin/puppet agent -t'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[5] '/usr/bin/puppet agent -t --debug'",
      "set spec[user = 'noordzee']/user noordzee",
      "set spec[user = 'noordzee']/host_group/host ALL",
      "set spec[user = 'noordzee']/host_group/command SERVICES",
      "set spec[user = 'noordzee']/host_group/command/runas_user root",
      "set spec[user = 'noordzee']/host_group/command/tag NOPASSWD",
      ],
  }

  file {
    '/home/noordzee/.bashrc': source => 'puppet:///modules/role_waarneming/noordzee_bashrc';
    '/home/noordzee/.bash_profile': source => 'puppet:///modules/role_waarneming/django_bash_profile';
  }

  file {
    '/home/noordzee/bin'                    : ensure => 'directory';
    '/home/noordzee/bin/flush_memcache.py'  : content => template('role_waarneming/noordzee_bin/flush_memcache.py.erb'), mode => '0755';
    '/home/noordzee/bin/remove_constraints' : content => template('role_waarneming/noordzee_bin/remove_constraints.erb'), mode => '0755';
    '/home/noordzee/bin/schema_cache'       : content => template('role_waarneming/noordzee_bin/schema_cache.erb'), mode => '0755';
  }

  file { '/home/noordzee/.ssh':
    ensure  => directory,
    mode    => '0700',
  }

  create_resources('ssh_authorized_key', $ssh_keys)

  # Place noordzee ssh key private and public parts
  file { '/home/noordzee/.ssh/id_rsa':
    mode    => '0600',
    content => $::role_waarneming::conf::git_repo_key_django,
    require => File['/home/noordzee/.ssh'],
  }

  ssh_authorized_key { 'noordzee@web':
    user    => 'noordzee',
    key     => $::role_waarneming::conf::ssh_key_noordzee,
    target  => '/home/noordzee/.ssh/id_rsa.pub',
    require => File['/home/noordzee/.ssh'],
  }

  # Check out bitbucket repo
  vcsrepo { '/home/noordzee/django':
    ensure   => $::role_waarneming::conf::git_repo_ensure_noordzee,
    provider => git,
    source   => $::role_waarneming::conf::git_repo_url_noordzee,
    revision => $::role_waarneming::conf::git_repo_rev_noordzee,
    user     => 'noordzee',
    require  => [
      File['/home/noordzee/.ssh/id_rsa'],
      Sshkey['bitbucket_org_rsa'],
      Sshkey['bitbucket_org_dsa'],
    ]
  }

  # Configure postgres user credentials in app
  file { '/home/noordzee/django/app/settings_local.py':
    content => template('role_waarneming/settings_local.py.erb'),
    replace => $::role_waarneming::conf::noordzee_managesettings,
    require => Vcsrepo['/home/noordzee/django'],
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
    version    => $python_version,
    dev        => present,
    virtualenv => present,
  }->
  ::python::virtualenv { '/home/noordzee/virtualenv' :
    ensure       => present,
    requirements => '/home/noordzee/django/requirements.txt',
    owner        => 'noordzee',
    group        => 'noordzee',
    require      => [
      Vcsrepo['/home/noordzee/django'],
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
    before => Exec['restart noordzee'],
  }

  file { '/etc/supervisor/conf.d/noordzee.conf':
    ensure  => present,
    owner  => 'root',
    group  => 'root',
    source  => 'puppet:///modules/role_waarneming/supervisor_noordzee.conf',
    require => Package['supervisor'],
    notify  => Service['supervisor'],
  }

  # Run migrate to update DB schema
  exec { 'migrate noordzee':
    command     => 'python manage.py migrate --noinput',
    path        => '/home/noordzee/virtualenv/bin/',
    cwd         => '/home/noordzee/django',
    user        => 'noordzee',
    require     => [
      File['/home/noordzee/django/app/settings_local.py'],
      Python::Virtualenv['/home/noordzee/virtualenv'],
    ],
    before      => Exec['restart noordzee'],
    subscribe   => Vcsrepo['/home/noordzee/django'],
    refreshonly => true,
    timeout     => 0,
  }

  exec { 'collectstatic noordzee':
    command     => 'python manage.py collectstatic --noinput',
    path        => '/home/noordzee/virtualenv/bin/',
    cwd         => '/home/noordzee/django',
    user        => 'noordzee',
    require     => [
      File['/home/noordzee/django/app/settings_local.py'],
      Python::Virtualenv['/home/noordzee/virtualenv'],
    ],
    before      => Exec['restart noordzee'],
    subscribe   => Vcsrepo['/home/noordzee/django'],
    refreshonly => true,
    timeout     => 0,
  }

  exec { 'restart noordzee':
    command     => '/usr/bin/supervisorctl restart noordzee',
    require     => File['/etc/supervisor/conf.d/noordzee.conf'],
    subscribe   => Vcsrepo['/home/noordzee/django'],
    refreshonly => true,
  }

  # Special defined resource until config is cleaned up
  # and we can use build-in nginx module resources
  # disabled while copying vhost config files verbatim
  #create_resources('::role_waarneming::vhost', $sites)
}
