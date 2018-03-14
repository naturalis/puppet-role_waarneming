# Install webserver and app
define role_waarneming::django_app(
  $repo_key,
  $repo_url,
  $repo_ensure,
  $repo_rev,
  $managesettings,
  $uid,
  $gid,
  $pg_dbname,
  $pg_user,
  $pg_password,
  $ssh_keys = {
    "${title}_obs_django"     => { user => $title, key => $::role_waarneming::conf::ssh_key_obs },
    "${title}_hugo_django"    => { user => $title, key => $::role_waarneming::conf::ssh_key_hugo },
    "${title}_dylan_django"   => { user => $title, key => $::role_waarneming::conf::ssh_key_dylan },
    "${title}_folkert_django" => { user => $title, key => $::role_waarneming::conf::ssh_key_folkert },
    "${title}_jieter_django"  => { user => $title, key => $::role_waarneming::conf::ssh_key_jieter },
    "${title}_b1_django"      => { user => $title, key => $::role_waarneming::conf::ssh_key_b1 },
    "${title}_b2_django"      => { user => $title, key => $::role_waarneming::conf::ssh_key_b2 },
    "${title}_bt_django"      => { user => $title, key => $::role_waarneming::conf::ssh_key_bt },
    "${title}_bh_django"      => { user => $title, key => $::role_waarneming::conf::ssh_key_bh },
  }
) {
  # Defaults for all file resources
  File {
    ensure => present,
    owner  => $title,
    group  => $title,
    mode   => '0644',
  }

  # Defaults for all ssh authorized keys
  Ssh_Authorized_Key {
    ensure => present,
    type   => 'ssh-rsa',
  }

  # Create user and place ssh key
  user { $title:
    ensure     => present,
    uid        => $uid,
    gid        => $gid,
    groups     => ['waarneming'],
    managehome => true,
    shell      => '/bin/bash',
    require    => Group[$title]
  }

  group { $title:
    ensure => present,
    gid    => $gid
  }



  # Add entries to sudoers. obs user can restart services. 
#  augeas { "sudorestart${title}":
#    context => "/files/etc/sudoers",
#    changes => [
#      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/name SERVICES",
#      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[1] '/usr/bin/supervisorctl start obs'",
#      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[2] '/usr/bin/supervisorctl stop obs'",
#      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[3] '/usr/bin/supervisorctl restart obs'",
#      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[4] '/usr/bin/puppet agent -t'",
#      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[5] '/usr/bin/puppet agent -t --debug'",
#      "set spec[user = 'obs']/user obs",
#      "set spec[user = 'obs']/host_group/host ALL",
#      "set spec[user = 'obs']/host_group/command SERVICES",
#      "set spec[user = 'obs']/host_group/command/runas_user root",
#      "set spec[user = 'obs']/host_group/command/tag NOPASSWD",
#      ],
#  }

  file {
    "/home/${title}/.bashrc":  content => template('role_waarneming/bashrc.erb');
    "/home/${title}/.bash_profile": source => 'puppet:///modules/role_waarneming/bash_profile';
  }

  file {
    "/home/${title}/bin"                             : ensure => 'directory';
    "/home/${title}/bin/flush_memcache.py"  : content => template('role_waarneming/django/flush_memcache.py.erb'), mode => '0755';
    "/home/${title}/bin/remove_constraints" : content => template('role_waarneming/django/remove_constraints.erb'), mode => '0755';
    "/home/${title}/bin/schema_cache"       : content => template('role_waarneming/django/schema_cache.erb'), mode => '0755';
  }

  file { "/home/${title}/.ssh":
    ensure  => directory,
    mode    => '0700',
  }

  create_resources('ssh_authorized_key', $ssh_keys)

  # Place obs ssh key private and public parts
  file { "/home/${title}/.ssh/id_rsa":
    mode    => '0600',
    content => $repo_key,
  }

  ssh_authorized_key { "${title}@web":
    user    => $title,
    key     => $::role_waarneming::conf::ssh_key_obs,
    target  => "/home/${title}/.ssh/id_rsa.pub",
    require => File["/home/${title}/.ssh"],
  }

  # Check out bitbucket repo
  vcsrepo { "/home/${title}/django":
    ensure   => $repo_ensure,
    provider => git,
    source   => $repo_url,
    revision => $repo_rev,
    user     => $title,
    require  => [
      File["/home/${title}/.ssh/id_rsa"],
      Sshkey['bitbucket_org_rsa'],
      Sshkey['bitbucket_org_dsa'],
    ]
  }

  # Configure postgres user credentials in app
  file { "/home/${title}/django/app/settings_local.py":
    content => template('role_waarneming/settings_local.py.erb'),
    replace => $managesettings,
    require => Vcsrepo["/home/${title}/django"],
  }

  # Install postgres python and dev libs
#  class { '::postgresql::lib::python': }
#  class { '::postgresql::lib::devel': }

  # Install packages needed by django-app
#  package { ['zlib1g-dev', 'libgdal1i']:
#    ensure  => present,
#    require => Class['apt::update'],
#  }

  # Install python, python-dev, virtualenv and create the virtualenv
#  class { '::python':
#    version    => $python_version,
#    dev        => present,
#    virtualenv => present,
#  }->
#  ::python::virtualenv { '/home/obs/virtualenv' :
#    ensure       => present,
#    requirements => '/home/obs/django/requirements.txt',
#    owner        => 'obs',
#    group        => 'obs',
#    require      => [
#      Vcsrepo['/home/obs/django'],
#      Class['postgresql::lib::devel'],
#    ],
#  }

  # Supervisord is used to manage the django UWSGI process
#  package { 'supervisor':
#    ensure  => present,
#    require => Class['apt::update'],
#  }

#  service { 'supervisor':
#    ensure  => running,
#    require => Package['supervisor'],
#  }

  # Create uwsgi socket dir
#  file { '/var/uwsgi':
#    ensure => directory,
#    owner  => 'root',
#    group  => 'root',
#    mode   => '0733',
#    before => Exec['restart obs'],
#  }

#  file { "/etc/supervisor/conf.d/${title}.conf":
#    ensure  => present,
#    owner  => 'root',
#    group  => 'root',
#    source  => 'puppet:///modules/role_waarneming/supervisor_obs.conf',
#    require => Package['supervisor'],
#    notify  => Service['supervisor'],
#  }

  # Run migrate to update DB schema
#  exec { 'migrate obs':
#    command     => 'python manage.py migrate --noinput',
#    path        => '/home/obs/virtualenv/bin/',
#    cwd         => '/home/obs/django',
#    user        => 'obs',
#    require     => [
#      File['/home/obs/django/app/settings_local.py'],
#      Python::Virtualenv['/home/obs/virtualenv'],
#    ],
#    before      => Exec['restart obs'],
#    subscribe   => Vcsrepo['/home/obs/django'],
#    refreshonly => true,
#    timeout     => 0,
#  }

#  exec { 'collectstatic obs':
#    command     => 'python manage.py collectstatic --noinput',
#    path        => '/home/obs/virtualenv/bin/',
#    cwd         => '/home/obs/django',
#    user        => 'obs',
#    require     => [
#      File['/home/obs/django/app/settings_local.py'],
#      Python::Virtualenv['/home/obs/virtualenv'],
#    ],
#    before      => Exec['restart obs'],
#    subscribe   => Vcsrepo['/home/obs/django'],
#    refreshonly => true,
#    timeout     => 0,
#  }

#  exec { 'restart obs':
#    command     => '/usr/bin/supervisorctl restart obs',
#    require     => File['/etc/supervisor/conf.d/obs.conf'],
#    subscribe   => Vcsrepo['/home/obs/django'],
#    refreshonly => true,
#  }

}
