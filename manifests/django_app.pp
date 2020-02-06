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
    'jieter_django'  => { user => 'obs', key => $::role_waarneming::conf::ssh_key_jieter },
    'sjaak_django'  => { user => 'obs', key => $::role_waarneming::conf::ssh_key_sjaak },
    'alex_django'    => { user => 'obs', key => $::role_waarneming::conf::ssh_key_alex },
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

  # Add entries to sudoers. obs user can restart services. 
  augeas { "sudorestartobs":
    context => "/files/etc/sudoers",
    changes => [
      "set Cmnd_Alias[alias/name = 'OBSSERVICES']/alias/name OBSSERVICES",
      "set Cmnd_Alias[alias/name = 'OBSSERVICES']/alias/command[1] '/usr/bin/supervisorctl start *'",
      "set Cmnd_Alias[alias/name = 'OBSSERVICES']/alias/command[2] '/usr/bin/supervisorctl stop *'",
      "set Cmnd_Alias[alias/name = 'OBSSERVICES']/alias/command[3] '/usr/bin/supervisorctl restart *'",
      "set Cmnd_Alias[alias/name = 'OBSSERVICES']/alias/command[4] '/usr/bin/puppet agent -t'",
      "set Cmnd_Alias[alias/name = 'OBSSERVICES']/alias/command[5] '/usr/bin/puppet agent -t --debug'",
      "set spec[user = 'obs']/user obs",
      "set spec[user = 'obs']/host_group/host ALL",
      "set spec[user = 'obs']/host_group/command OBSSERVICES",
      "set spec[user = 'obs']/host_group/command/runas_user root",
      "set spec[user = 'obs']/host_group/command/tag NOPASSWD",
      ],
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

  exec { 'ssh_known_host_github_obs':
     command => '/usr/bin/ssh-keyscan github.com >> /home/obs/.ssh/known_hosts',
     unless  => '/bin/grep github.com /home/obs/.ssh/known_hosts',
     user    => 'obs',
   }

  # Check out bitbucket repo
  vcsrepo { '/home/obs/django':
    ensure   => $::role_waarneming::conf::git_repo_ensure_django,
    provider => git,
    source   => $::role_waarneming::conf::git_repo_url_django,
    revision => $::role_waarneming::conf::git_repo_rev_django,
    user     => 'obs',
    trust_server_cert => true,
    require  => [
      File['/home/obs/.ssh/id_rsa'],
      Exec['ssh_known_host_github_obs'],
    ]
  }

  # Configure postgres user credentials in app
  file { '/home/obs/django/.env':
    content => template('role_waarneming/.env.erb'),
    replace => $::role_waarneming::conf::obs_managesettings,
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

  ensure_packages(['libjpeg-dev','libpng12-dev','ffmpeg'])

  apt::source { 'deadsnakes':
    location => 'http://ppa.launchpad.net/deadsnakes/ppa/ubuntu/',
    release  => 'xenial',
    repos    => 'main',
    key      => {
      'id'     => 'F23C5A6CF475977595C89F51BA6932366A755776',
      'server' => 'keyserver.ubuntu.com',
    },
    notify   => Exec['apt_update']
  }
  package {['python3.7-minimal', 'python3.7-dev']:
    require   => Apt::Source['deadsnakes']
  }

  # libgdal20 is required for Django 3.0 and not present in Ubuntu 16.04
  ::apt::ppa { 'ppa:ubuntugis/ppa': }
  package { ['libgdal20']:
    ensure  => present,
    require => [Class['apt::update'], Apt::Ppa['ppa:ubuntugis/ppa']],
  }

  # Install python, python-dev, virtualenv and create the virtualenv
  class { '::python':
    dev        => present,
    virtualenv => present,
  }->
  python::virtualenv { '/home/obs/virtualenv' :
    version      => '3.7',
    distribute   => false,
    ensure       => present,
    requirements => '/home/obs/django/requirements.txt',
    extra_pip_args => '--no-binary :none:',
    owner        => 'obs',
    group        => 'obs',
    require      => [
      Vcsrepo['/home/obs/django'],
      Class['postgresql::lib::devel'],
      Package['libjpeg-dev','libpng12-dev']
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

  file { '/etc/supervisor/conf.d/obs-beat.conf':
    ensure  => present,
    owner  => 'root',
    group  => 'root',
    source  => 'puppet:///modules/role_waarneming/supervisor_obs-beat.conf',
    require => Package['supervisor'],
    notify  => Service['supervisor'],
  }

  file { '/etc/supervisor/conf.d/obs-worker.conf':
    ensure  => present,
    owner  => 'root',
    group  => 'root',
    source  => 'puppet:///modules/role_waarneming/supervisor_obs-worker.conf',
    require => Package['supervisor'],
    notify  => Service['supervisor'],
  }

  file { '/etc/supervisor/conf.d/obs-worker2.conf':
    ensure  => present,
    owner  => 'root',
    group  => 'root',
    source  => 'puppet:///modules/role_waarneming/supervisor_obs-worker2.conf',
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
      File['/home/obs/django/.env'],
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
      File['/home/obs/django/.env'],
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

  # Project app instance
  # There is probably a better way to only apply this to the test environment
  if ($::role_waarneming::conf::git_repo_rev_django == 'develop') {
    vcsrepo { '/home/obs/project':
      ensure   => $::role_waarneming::conf::git_repo_ensure_django,
      provider => git,
      source   => $::role_waarneming::conf::git_repo_url_django,
      revision => 'project',
      user     => 'obs',
      trust_server_cert => true,
      require  => [
        File['/home/obs/.ssh/id_rsa'],
        Exec['ssh_known_host_github'],
      ]
    }
    file { '/home/obs/project/.env':
      content => template('role_waarneming/.env.erb'),
      replace => $::role_waarneming::conf::obs_managesettings,
      require => Vcsrepo['/home/obs/project'],
    }
    file { '/etc/supervisor/conf.d/project.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/role_waarneming/supervisor_project.conf',
      require => Package['supervisor'],
      notify  => Service['supervisor'],
    }
  }

  # Special defined resource until config is cleaned up
  # and we can use build-in nginx module resources
  # disabled while copying vhost config files verbatim
  #create_resources('::role_waarneming::vhost', $sites)
}
