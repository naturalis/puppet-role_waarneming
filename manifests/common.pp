# common actions for all servers
class role_waarneming::common (
) {
  # Install all locales
  package { 'locales-all':
    ensure => present,
  }

  # Create rsync, waarneming and obs groups to allow dependencies
  group { 'obs':
    ensure => present,
    gid    => '3000',
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
    groups     => [ 'obs', 'waarneming' ],
    managehome => true,
  }

  file { '/home/rsync/.ssh':
    ensure  => directory,
    owner   => 'rsync',
    group   => 'rsync',
    mode    => '0700',
  }

  # Add authorized ssh keys
  $rsync_ssh_options = [
    'command="rsync --config=/root/.rsyncd.conf --server --daemon ."',
    'no-agent-forwarding',
    'no-port-forwarding',
    'no-pty',
    'no-user-rc',
    'no-X11-forwarding'
  ]

  $rsync_ssh_defaults = {
    'ensure'  => present,
    'user'    => 'rsync',
    'options' => $rsync_ssh_options,
  }

  $rsync_keys = {
    'b1_rsync' => {
      key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDRWXTse+ZP8rfMARlbDWrMmLaN+XUssegSPxS9KgPDHv2uy3QSAHkPSyAOR0rAowVMS6ocOuT8QDmQ4q4hZBDz4o6KU3m5M2GDpV7ZWQU/PmaMKnAs6AFaKlNDaVZPyqH0DirRiYTd6SHcHer/jJCnHaqOaD1S5KZ/GMAugmzX+2dVe+D/K+gKze6I9e+B/mGREOAyQXeY4IXDZFPkyRL4Q6oyhUiC+bmcy67awnnLSSP+KwNLkOBsLUmXwOlZD/nFVmSyAfJrOVid3/QTmInlsyklHy0DzMMNETn27343v8nD1D33VjrrFIWxsq8O0+s+RdLxxaj7kdFHJqEf0Q4Z',
    },
    'b2_rsync' => {
      key     => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1TPTzcVQnur3jlLQQGGfyorMrE/41Ply56zamCcpTql4D0hPaOwm9ZHVsMw4HEPsIZiizHO3Edsu8mpN8NjooM6gKqcEDv9kt1sJLxlIf7gV767Nuy9gbA4VvNMAC88zYrp4sJF+T3bWkva7gCHcz9a1yNUaduyLDk6KQxkpy18+6RnJi7LhUE9MP5eoNfQApvCO/LiARDKQce+Ot/jbG9ufqmOBKPwX3Vo0sNKlcgMbQ7vmUFf85rzlChsWpXT7rojJ26xKYM9ds1YX0JJ0POBCygFH4cxf40BrSfWkZEhS7agx3yG6XGDIlMJG2pbtsLtJ30thBhUgTw+aFP3aaw=='
    },
    'bt_rsync' => {
      key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQChcEpQ/K9KZlOJJnlQf+RomJeqtjacPOI5ociblmVKfQwEitfw21yU77TPZWAVKlaFiPyBrzMGS6/2weDTyWxXsT+dFzKUWSSprd+9vzIWrueBGUXxzgfgn0Q5fn0j1HYGH6EBEeo7QR3rI3OyTFLwvtLe06Fef4JlXljFa1o/TlOw1hkO8uGqq4eAM9DXWOrTV4Zzr945XoOzgGCfHi2Z3CjAnZ0EVWB81I624d0llhLaOVzyJsYCtYA5gVITYcduOwkCMjk36RNR+FngoYtmIcppp3EKpsV5z4xn0JEt9WfRDD7ISaj7zkZVTCNg9G3wKvNSW11HzDMTQRZkThmR'
    },
    'bh_rsync' => {
      key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDaqCYEAZesYnGZI0E+/vm+WoiVzpIVTgdKnuDGEGU8x5qkgqbjS8M8+loZGx/qt+bgzTwvNycqcz0ucKFgTNpr5yDS+aILY06AETRF2hhA5XGVh/TozlZff1fWagIacnY2+Zl+X/WrahYro9z+I69mnmz++Wy2DsHJqYI51Schn4RKeeM99EIiP1qa3uVkin4ouetLI1fUt7ZB/EsM+OG3urmnsBskrLA1Uyg1s8qbk98lxrbKhBqMUM2Sk32chX0/l69t/TWF3wqtn9Auc9nRLNOTRJDKV6BMSbilZxgOvraSJqy8zqrnmPAqkiGI0wfpMyowJ52QLQBUY4txadFX'
    },
  }

  create_resources(ssh_authorized_key, $rsync_keys, $rsync_ssh_defaults)
}
