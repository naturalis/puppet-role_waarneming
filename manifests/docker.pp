# == Class: role_waarneming::docker
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
# === Copyright
#
# Apache2 license 2017.
#
class role_waarneming::docker (
){

  include 'docker'
  include 'stdlib'

  Exec {
    path => '/usr/local/bin/',
    cwd  => "${role_waarneming::conf::docker_repo_dir}",
  }

  file {$role_waarneming::conf::docker_repo_dir:
    ensure      => 'directory',
  }

  class {'docker::compose':
    ensure      => present,
    version     => $role_waarneming::conf::docker_compose_version
  }


  vcsrepo { $role_waarneming::conf::docker_repo_dir:
    ensure    => $role_waarneming::conf::docker_repo_ensure,
    source    => $role_waarneming::conf::docker_repo_source,
    provider  => 'git',
    user      => 'root',
    revision  => 'master',
    require   => [Package['git'],File[$role_waarneming::conf::docker_repo_dir]]
  }

  docker_compose { "${role_waarneming::conf::docker_repo_dir}/docker-compose.yml":
    ensure      => present,
    require     => [ 
      Vcsrepo[$role_waarneming::conf::docker_repo_dir],
    ]
  }

  exec { 'Pull containers' :
    command  => 'docker-compose pull',
    schedule => 'everyday',
  }

  exec { 'Up the containers to resolve updates' :
    command  => 'docker-compose up -d',
    schedule => 'everyday',
    require  => Exec['Pull containers']
  }

  exec {'Restart containers on change':
    refreshonly => true,
    command     => 'docker-compose up -d',
    require     => Docker_compose["${role_waarneming::conf::docker_repo_dir}/docker-compose.yml"],
  }

  # deze gaat per dag 1 keer checken
  # je kan ook een range aan geven, bv tussen 7 en 9 's ochtends
  schedule { 'everyday':
     period  => daily,
     repeat  => 1,
     range => '5-7',
  }

}
