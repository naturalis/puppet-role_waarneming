# Install and configure mailserver
class role_waarneming::mail (
) {
  # Install postfix
  # listen only on local interfaces
  # set domain as origin
  class { '::postfix':
    inet_interfaces => '127.0.0.1',
    myorigin        => 'waarneming.nl',
    myhostname      => 'mail.waarneming.nl',
  }

  postfix::config { 'inet_protocols':
    ensure  => present,
    value   => 'ipv4',
  }

  postfix::config { 'smtp_destination_concurrency_limit':
    ensure  => present,
    value   => '2',
  }

  postfix::config { 'smtp_destination_rate_delay':
    ensure  => present,
    value   => '1s',
  }

  postfix::config { 'smtp_extra_recipient_limit':
    ensure  => present,
    value   => '10',
  }

  # adjust default rsyslog config for removing mail logging from syslog and to mail.log and mail.err only
  file_line { 'rsyslog config':
    ensure             => present,
    path               => '/etc/rsyslog.d/50-default.conf',
    line               => '*.*;mail.none,auth,authpriv.none       -/var/log/syslog',
    match              => '^*.*;auth,authpriv.none',
    notify             => Exec['restart rsyslog'],
  }

  # restart syslog when config is adjusted
  exec { 'restart rsyslog':
    refreshonly     => true,
    path            => ['/usr/bin', '/usr/sbin','/bin','/sbin'],
    command         => 'systemctl restart rsyslog.service'
  }

}
