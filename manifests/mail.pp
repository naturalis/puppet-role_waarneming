# Install and configure mailserver
class role_waarneming::mail (
) {
  # Install postfix
  # listen only on local interfaces
  # set domain as origin
  class { '::postfix':
    inet_interfaces => '127.0.0.1',
    myorigin        => 'waarneming.nl',
  }

  postfix::config { 'inet_protocols':
    ensure  => present,
    value   => 'ipv4',
  }

  postfix::config { 'smpt_destination_concurrency_limit':
    ensure  => present,
    value   => '2',
  }

  postfix::config { 'smpt_destination_rate_delay':
    ensure  => present,
    value   => '1s',
  }

  postfix::config { 'smpt_extra_recipient_limit':
    ensure  => present,
    value   => '10',
  }

}
