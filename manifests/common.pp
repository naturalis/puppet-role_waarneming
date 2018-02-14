# common actions for all servers
class role_waarneming::common (
) {
  # Install all locales
  package { 'locales-all':
    ensure => present,
  }

  # Set timezone to Amsterdam
  class { 'timezone':
    timezone => 'Europe/Amsterdam',
  }

  # Create rsync, waarneming and obs groups to allow dependencies
  group { 'obs':
    ensure => present,
    gid    => '3000',
  }

  group { 'noordzee':
    ensure => present,
    gid    => '3010',
  }

  group { 'nederlandzoemt':
    ensure => present,
    gid    => '3020',
  }

  group { 'rsync':
    ensure => present,
    gid    => '3001',
  }

  group { 'waarneming':
    ensure => present,
    gid    => '3107',
  }

  # Create special rsync user for backup sync
  user { 'rsync':
    ensure     => present,
    uid        => '3001',
    gid        => '3001',
    groups     => [ 'obs', 'waarneming', 'noordzee', 'nederlandzoemt' ],
    managehome => true,
  }

  file { '/home/rsync/.rsyncd.conf':
    ensure => present,
    owner  => 'rsync',
    group  => 'rsync',
    mode   => '0644',
    source => 'puppet:///modules/role_waarneming/rsyncd.conf',
  }

  file { '/home/rsync/.ssh':
    ensure => directory,
    owner  => 'rsync',
    group  => 'rsync',
    mode   => '0700',
  }

  # Add authorized ssh keys
  $rsync_ssh_options = [
    'command="rsync --config=/home/rsync/.rsyncd.conf --server --daemon ."',
    'no-agent-forwarding',
    'no-port-forwarding',
    'no-pty',
    'no-user-rc',
    'no-X11-forwarding'
  ]

  $rsync_ssh_defaults = {
    'ensure'  => present,
    'user'    => 'rsync',
    'type'    => 'ssh-rsa',
    'options' => $rsync_ssh_options,
  }

  $rsync_keys = {
    'b1_rsync' => {
      key     => $::role_waarneming::conf::ssh_key_b1,
    },
    'b2_rsync' => {
      key     => $::role_waarneming::conf::ssh_key_b2,
    },
    'bt_rsync' => {
      key     => $::role_waarneming::conf::ssh_key_bt,
    },
    'bh_rsync' => {
      key     => $::role_waarneming::conf::ssh_key_bh,
    },
  }

  create_resources(ssh_authorized_key, $rsync_keys, $rsync_ssh_defaults)
}
