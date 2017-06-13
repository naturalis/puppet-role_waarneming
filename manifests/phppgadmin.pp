# == Class role_waarneming::phppgadmin
#
class role_waarneming::phppgadmin (
  $path                         = '/srv/phppgadmin',
  $user                         = 'www-data',
  $servers                      = [],
  $revision                     = 'origin/REL_5-1',
  $enableletsencrypt            = false,
  $letsencrypt_email            = 'letsencypt@mydomain.me',
  $letsencrypt_version          = 'master',
  $letsencrypt_domains          = ['phppgadmin.site.nl'],
  $letsencrypt_server           = 'https://acme-v01.api.letsencrypt.org/directory',
) {

  file { $path:
    ensure => directory,
    owner  => $user,
  } ->

  vcsrepo { $path:
    ensure   => present,
    provider => git,
    source   => 'git://github.com/phppgadmin/phppgadmin.git',
    user     => $user,
    revision => $revision,
  }

  package { 'php' :
    ensure   => present,
    settings => {
      'PHP/max_execution_time' => '900',
    }
  }

  package { 'php7.0-pgsql' :
    ensure => present,
  }

  package { 'postgresql-client' :
    ensure => present,
  }

  class { 'nginx': }

  if ($role_waarneming::phppgadmin::enableletsencrypt == true) {
    $sslfolder = $role_waarneming::phppgadmin::letsencrypt_domains[0]
    nginx::resource::server { 'phppgadmin':
      www_root             => '/srv/phppgadmin',
      use_default_location => false,
      listen_port           => 443,
      ssl                   => true,
      ssl_cert              => "/etc/letsencrypt/live/${sslfolder}/cert.pem",
      ssl_key               => "/etc/letsencrypt/live/${sslfolder}/privkey.pem",
    }
    nginx::resource::server { 'phppgadmin_nonssl':
      location_cfg_append   => { 'rewrite' => "^ https://${sslfolder} permanent" },
    }
  }else{
    nginx::resource::server { 'phppgadmin':
      www_root             => '/srv/phppgadmin',
      use_default_location => false
    }
  }

  nginx::resource::location { "phppgadmin":
    ensure              => present,
    server              => 'phppgadmin',
    www_root            => '/srv/phppgadmin',
    ssl_only            => $role_waarneming::phppgadmin::enableletsencrypt,
    location            => '~ \.php$',
    location_cfg_append => {
      'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
      'fastcgi_param'           => 'SCRIPT_FILENAME $document_root/$fastcgi_script_name',
      'fastcgi_pass'            => '127.0.0.1:9000',
      'fastcgi_index'           => 'index.php',
      'include'                 => 'fastcgi_params',
      'fastcgi_read_timeout'    => '900'
    },
    notify              => Class['nginx::service'],
  }

  file_line{'phppgadmin_conf_file_host':
    path    => '/srv/phppgadmin/conf/config.inc.php',
    match   => "\\t\\\$conf\\['servers'\\]\\[0\\]\\['host'\\] = '.*';$",
    line    => "\t\$conf['servers'][0]['host'] = '${role_waarneming::conf::db_host}';",
    require => Vcsrepo[$path],
  }

# install letsencrypt certs only and crontab
  if ($role_waarneming::phppgadmin::enableletsencrypt == true) {
  $firstcert = $role_waarneming::phppgadmin::letsencrypt_domains[0]
   anchor { 'role_waarneming::phppgadmin::begin': }
     -> exec { 'stop nginx':
        command        => "/usr/sbin/service nginx stop",
        require        => Class['nginx'],
        unless         => "/usr/bin/test -d /etc/letsencrypt/live/${firstcert}",
      }
     -> class { ::letsencrypt:
        config => {
          email  => $role_waarneming::phppgadmin::letsencrypt_email,
          server => $role_waarneming::phppgadmin::letsencrypt_server,
        }
      }
     -> letsencrypt::certonly { 'letsencrypt_cert':
        domains               => $role_waarneming::phppgadmin::letsencrypt_domains,
        cron_before_command   => 'service nginx stop',
        cron_success_command  => '/bin/systemctl reload nginx.service',
        manage_cron           => true,
      }
     -> exec { 'start nginx':
        command        => "/usr/sbin/service nginx start",
        unless         => "/usr/bin/test -d /etc/letsencrypt/live/${firstcert}",
      }
    anchor { 'role_waarneming::phppgadmin::end': }
  }
}
