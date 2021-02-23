# Install and configure webserver
class role_waarneming::web (
) {
  # Defaults for all file resources
  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Git is needed for both PHP and Django websites
  include git

  # Add required keys to system-wide known_hosts
  sshkey { 'bitbucket_org_rsa':
    ensure       => present,
    host_aliases => 'bitbucket.org',
    type         => 'ssh-rsa',
    key          => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==',
  }

  sshkey { 'bitbucket_org_dsa':
    ensure       => present,
    host_aliases => 'bitbucket.org',
    type         => 'ssh-dss',
    key          => 'AAAAB3NzaC1kc3MAAACBAO53E7Kcxeak0luot3Z5ulOQJoLRBcnBQb0gpUfNL5rZW63fBubfXLbpZc2/GnHxRiFa2okTPvBULJZnjwXltyoRfjPICRLfH/ep3mZj6CVUyQgxES27CS1bEjMw8+S6hLlJF4dKqOIWH5+Ed+lo8ezzXbzcEj7R5h9xGgfY55HfAAAAFQDE/aqj+0sxv/ZRS3ArGxMHGYFebwAAAIEA6lZ68WgDMrR28iXIicJ7AnXPnZKzQK7xK68feKlYo9LcEkKTF3AZIE5nEvtn+ZYwZ5cKE3XKeU42aesAEAUxX9cUEzhi87q6PQagD6ZPcU89CCVlWsG8cKYCZ6VtMfcLU06grNfvl450KCHltWTaoBHdi9f8eFo3Gydg6JhyNJ8AAACAThcLJmru5QtpHo9wctg5jHKxv1BLPndKs3dVwAQwcd2sugoymGeH7IjBSFLqHsyl7XpDik4mH/YdkVwb1jAwA+JOu2gHpsSXLY22At+LKn6NHdL/qqbIf7ellnKXfEo+wz6DfGihaczY931WrjkEEsq1453/4BwQpAXrz2zbRSI=',
  }

  # Activate redis service
  class { '::redis': }

  # Activate memcached service
  class { 'memcached':
    max_memory    => 1024,
    max_item_size => '10M',
    user          => 'memcache',
    listen_ip     => '127.0.0.1',
    pidfile       => false,
    install_dev   => true,
  }

  # Install nginx
  class { '::nginx':
    super_user  => true,
    daemon_user => 'waarneming',
    worker_rlimit_nofile => '4096',
    worker_processes => $::role_waarneming::conf::nginx_worker_processes,
    log_format  => {
      custom => '{ "@timestamp": "$time_iso8601", "http_host": "$http_host", "remote_addr": "$remote_addr", "remote_user": "$remote_user", "bytes_sent": $bytes_sent, "body_bytes_sent": $body_bytes_sent, "request_length": $request_length, "request_time": $request_time, "status": "$status", "request": "$request", "request_method": "$request_method", "http_referrer": "$http_referer", "http_user_agent": "$http_user_agent" }'
    },
  }

  # Nginx include files, verbatim
  file { '/etc/nginx/include':
    source  => 'puppet:///modules/role_waarneming/nginx_include',
    recurse => true,
    notify  => Service['nginx'],
    require => Package['nginx'],
  }
  
  # Nginx conf.d/rate-limit.conf
  file { '/etc/nginx/conf.d/rate-limit.conf':
    source  => 'puppet:///modules/role_waarneming/nginx_conf_d/rate-limit.conf',
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  # Nginx phppgadmin.conf include config
  file { '/etc/nginx/include/phppgadmin.conf':
    content => template('role_waarneming/phppgadmin.conf.erb'),
    notify  => Service['nginx'],
  }

  # Add users to Nginx htpasswd file
  create_resources('htpasswd', $::role_waarneming::conf::nginx_allow_user, {'target' => '/etc/nginx/include/.htpasswd', 'require' => Service['nginx']})

  # Nginx include block_ip.conf
  file { '/etc/nginx/include/block_ip.conf':
    content => epp('role_waarneming/nginx_block_ip.epp', {'htpassfile' => '.htpasswd'}),
    notify  => Service['nginx'],
  }

  # Nginx include block_ip_intern.conf
  file { '/etc/nginx/include/block_ip_intern.conf':
    content => epp('role_waarneming/nginx_block_ip.epp', {'htpassfile' => '.htpasswd'}),
    notify  => Service['nginx'],
  }

  include ::role_waarneming::sites

  # Script to set nginx in offline mode
  file { '/usr/local/bin/sites_offline.sh':
    source => 'puppet:///modules/role_waarneming/sites_offline.sh',
    mode   => '0755',
  }

  # Install additional fonts
  package { ['ttf-dejavu-core','ttf-dejavu-extra']:
    ensure => present,
  }

  # Install exif for metadata extraction from images
  package { 'exif':
    ensure => present,
  }

  # Install libfile-mimeinfo-perl used for uploads
  package { 'libfile-mimeinfo-perl':
    ensure => present,
  }

  # Install gettext for obs
  package { 'gettext':
    ensure => present,
  }

  # Install postgis
  package { 'postgis':
    ensure => present,
    install_options => [ '--no-install-recommends' ],
  }

  # Script to rsync media files from production to test, acc or dev. 
  file { '/usr/local/sbin/rsync_media.sh':
    content => template('role_waarneming/rsync_media.erb'),
    mode   => '0755',
  }

  # Script to set nginx in offline mode
  file { '/etc/logrotate.d/rsync_media':
    source => 'puppet:///modules/role_waarneming/rsync_logrotate',
    mode   => '0644',
  }

  if ($::role_waarneming::conf::rsync_media == true){
    cron { 'rsync media':
      command => '/usr/local/sbin/rsync_media.sh',
      user    => root,
      hour    => $::role_waarneming::conf::rsync_cron_hour,
      minute  => $::role_waarneming::conf::rsync_cron_minute,
      weekday => $::role_waarneming::conf::rsync_cron_weekday
    }
  }
}
