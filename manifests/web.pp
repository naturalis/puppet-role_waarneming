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
  package { 'git':
    ensure => present,
  }

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
    max_memory  => 1024,
    user        => 'memcache',
    listen_ip   => '127.0.0.1',
    pidfile     => false,
    install_dev => true,
  }

  # Install nginx
  class { '::nginx':
    super_user  => true,
    daemon_user => 'waarneming',
    log_format  => {
      custom => '{ "@timestamp": "$time_iso8601", "@fields": { "http_host": "$http_host", "remote_addr": "$remote_addr", "remote_user": "$remote_user", "bytes_sent": $bytes_sent, "body_bytes_sent": $body_bytes_sent, "request_length": $request_length, "request_time": $request_time, "status": "$status", "request": "$request", "request_method": "$request_method", "http_referrer": "$http_referer", "http_user_agent": "$http_user_agent" } }'
    },
  }

  # Nginx include files, verbatim
  file { '/etc/nginx/include':
    source  => 'puppet:///modules/role_waarneming/nginx_include',
    recurse => true,
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  # Nginx include block_ip
  file { '/etc/nginx/include/block_ip':
    content => template('role_waarneming/nginx_block_ip.erb'),
    notify  => Service['nginx'],
    require => [Package['nginx'],File['/etc/nginx/include']]
  }
}
