# Install webserver and app
class role_waarneming::django_nederlandzoemt_app (
  $python_version = $::role_waarneming::conf::nederlandzoemt_python_version,
  $sites = {
    'django_nederlandzoemt' => {
      'ssl_key'     => $::role_waarneming::conf::observation_key,
      'ssl_crt'     => $::role_waarneming::conf::observation_crt,
      'server_name' => 'test-nl.observation.org test-be.observation.org',
    },
  },

  $ssh_keys = {
    'nederlandzoemt_django'     => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_nederlandzoemt },
    'hugo_django'    => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_hugo },
    'dylan_django'   => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_dylan },
    'folkert_django' => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_folkert },
    'jieter_django'  => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_jieter },
    'b1_django'      => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_b1 },
    'b2_django'      => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_b2 },
    'bt_django'      => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_bt },
    'bh_django'      => { user => 'nederlandzoemt', key => $::role_waarneming::conf::ssh_key_bh },
  }
) {
  # Install and configure webserver
  include ::role_waarneming::web

  # Defaults for all file resources
  File {
    ensure => present,
    owner  => 'nederlandzoemt',
    group  => 'nederlandzoemt',
    mode   => '0644',
  }

  # Defaults for all ssh authorized keys
  Ssh_Authorized_Key {
    ensure => present,
    type   => 'ssh-rsa',
  }

  # Create user and place ssh key
  user { 'nederlandzoemt':
    ensure     => present,
    uid        => '3020',
    gid        => '3020',
    groups     => ['waarneming'],
    managehome => true,
    shell      => '/bin/bash',
  }

  # Add entries to sudoers. nederlandzoemt user can restart services. 
  augeas { "sudorestartnederlandzoemt":
    context => "/files/etc/sudoers",
    changes => [
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/name SERVICES",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[1] '/usr/bin/supervisorctl start nederlandzoemt'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[2] '/usr/bin/supervisorctl stop nederlandzoemt'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[3] '/usr/bin/supervisorctl restart nederlandzoemt'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[4] '/usr/bin/puppet agent -t'",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[5] '/usr/bin/puppet agent -t --debug'",
      "set spec[user = 'nederlandzoemt']/user nederlandzoemt",
      "set spec[user = 'nederlandzoemt']/host_group/host ALL",
      "set spec[user = 'nederlandzoemt']/host_group/command SERVICES",
      "set spec[user = 'nederlandzoemt']/host_group/command/runas_user root",
      "set spec[user = 'nederlandzoemt']/host_group/command/tag NOPASSWD",
      ],
  }

  file {
    '/home/nederlandzoemt/.bashrc': source => 'puppet:///modules/role_waarneming/nederlandzoemt_bashrc';
    '/home/nederlandzoemt/.bash_profile': source => 'puppet:///modules/role_waarneming/django_bash_profile';
  }

  file {
    '/home/nederlandzoemt/bin'                    : ensure => 'directory';
    '/home/nederlandzoemt/bin/flush_memcache.py'  : content => template('role_waarneming/nederlandzoemt_bin/flush_memcache.py.erb'), mode => '0755';
    '/home/nederlandzoemt/bin/remove_constraints' : content => template('role_waarneming/nederlandzoemt_bin/remove_constraints.erb'), mode => '0755';
    '/home/nederlandzoemt/bin/schema_cache'       : content => template('role_waarneming/nederlandzoemt_bin/schema_cache.erb'), mode => '0755';
  }

  file { '/home/nederlandzoemt/.ssh':
    ensure  => directory,
    mode    => '0700',
  }

  create_resources('ssh_authorized_key', $ssh_keys)

  # Place nederlandzoemt ssh key private and public parts
  file { '/home/nederlandzoemt/.ssh/id_rsa':
    mode    => '0600',
    content => $::role_waarneming::conf::git_repo_key_django,
    require => File['/home/nederlandzoemt/.ssh'],
  }

  ssh_authorized_key { 'nederlandzoemt@web':
    user    => 'nederlandzoemt',
    key     => $::role_waarneming::conf::ssh_key_nederlandzoemt,
    target  => '/home/nederlandzoemt/.ssh/id_rsa.pub',
    require => File['/home/nederlandzoemt/.ssh'],
  }

  # Check out bitbucket repo
  vcsrepo { '/home/nederlandzoemt/django':
    ensure   => $::role_waarneming::conf::git_repo_ensure_nederlandzoemt,
    provider => git,
    source   => $::role_waarneming::conf::git_repo_url_nederlandzoemt,
    revision => $::role_waarneming::conf::git_repo_rev_nederlandzoemt,
    user     => 'nederlandzoemt',
    require  => [
      File['/home/nederlandzoemt/.ssh/id_rsa'],
      Sshkey['bitbucket_org_rsa'],
      Sshkey['bitbucket_org_dsa'],
    ]
  }

  # Configure postgres user credentials in app
  file { '/home/nederlandzoemt/django/app/settings_local.py':
    content => template('role_waarneming/settings_local.py.erb'),
    replace => $::role_waarneming::conf::nederlandzoemt_managesettings,
    require => Vcsrepo['/home/nederlandzoemt/django'],
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
  ::python::virtualenv { '/home/nederlandzoemt/virtualenv' :
    ensure       => present,
    requirements => '/home/nederlandzoemt/django/requirements.txt',
    owner        => 'nederlandzoemt',
    group        => 'nederlandzoemt',
    require      => [
      Vcsrepo['/home/nederlandzoemt/django'],
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
    before => Exec['restart nederlandzoemt'],
  }

  file { '/etc/supervisor/conf.d/nederlandzoemt.conf':
    ensure  => present,
    owner  => 'root',
    group  => 'root',
    source  => 'puppet:///modules/role_waarneming/supervisor_nederlandzoemt.conf',
    require => Package['supervisor'],
    notify  => Service['supervisor'],
  }

  # Run migrate to update DB schema
  exec { 'migrate nederlandzoemt':
    command     => 'python manage.py migrate --noinput',
    path        => '/home/nederlandzoemt/virtualenv/bin/',
    cwd         => '/home/nederlandzoemt/django',
    user        => 'nederlandzoemt',
    require     => [
      File['/home/nederlandzoemt/django/app/settings_local.py'],
      Python::Virtualenv['/home/nederlandzoemt/virtualenv'],
    ],
    before      => Exec['restart nederlandzoemt'],
    subscribe   => Vcsrepo['/home/nederlandzoemt/django'],
    refreshonly => true,
    timeout     => 0,
  }

  exec { 'collectstatic nederlandzoemt':
    command     => 'python manage.py collectstatic --noinput',
    path        => '/home/nederlandzoemt/virtualenv/bin/',
    cwd         => '/home/nederlandzoemt/django',
    user        => 'nederlandzoemt',
    require     => [
      File['/home/nederlandzoemt/django/app/settings_local.py'],
      Python::Virtualenv['/home/nederlandzoemt/virtualenv'],
    ],
    before      => Exec['restart nederlandzoemt'],
    subscribe   => Vcsrepo['/home/nederlandzoemt/django'],
    refreshonly => true,
    timeout     => 0,
  }

  exec { 'restart nederlandzoemt':
    command     => '/usr/bin/supervisorctl restart nederlandzoemt',
    require     => File['/etc/supervisor/conf.d/nederlandzoemt.conf'],
    subscribe   => Vcsrepo['/home/nederlandzoemt/django'],
    refreshonly => true,
  }

  # Special defined resource until config is cleaned up
  # and we can use build-in nginx module resources
  # disabled while copying vhost config files verbatim
  #create_resources('::role_waarneming::vhost', $sites)
}
