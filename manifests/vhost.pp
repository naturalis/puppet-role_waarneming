# Creates ssl key file, ssl cert file and vhost config file in one go
define role_waarneming::vhost (
  $ssl_key,
  $ssl_crt,
  $server_name,
  $site = $title
) {
  $defaults = {
    'notify' => Service['nginx'],
  }

  file { "/etc/ssl/${site}_key.pem":
    content => $ssl_key,
  }

  file { "/etc/ssl/${site}_crt.pem":
    content => $ssl_crt,
  }

  file { "/etc/nginx/sites-enabled/${site}":
    content => template('role_waarneming/vhost.erb'),
  }
}
