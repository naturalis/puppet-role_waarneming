# Copy all website configs verbatim
class role_waarneming::sites (
  $defaults = { require => Package['nginx'] },
  $certs_and_keys = {
    '/etc/nginx/ssl/waarneming_nl-chained.crt'   => { content => $::role_waarneming::conf::waarneming_nl_crt },
    '/etc/nginx/ssl/observation_org-chained.crt' => { content => $::role_waarneming::conf::observation_org_crt },
    '/etc/nginx/ssl/observations_be-chained.crt' => { content => $::role_waarneming::conf::observations_be_crt },
    '/etc/nginx/ssl/waarnemingen_be-chained.crt' => { content => $::role_waarneming::conf::waarnemingen_be_crt },
    '/etc/nginx/ssl/www_wnimg_nl-chained.crt'    => { content => $::role_waarneming::conf::www_wnimg_nl_crt },
    '/etc/nginx/ssl/waarneming_nl.key'           => { content => $::role_waarneming::conf::waarneming_nl_key },
    '/etc/nginx/ssl/observation_org.key'         => { content => $::role_waarneming::conf::observation_org_key },
    '/etc/nginx/ssl/observations_be.key'         => { content => $::role_waarneming::conf::observations_be_key },
    '/etc/nginx/ssl/waarnemingen_be.key'         => { content => $::role_waarneming::conf::waarnemingen_be_key },
    '/etc/nginx/ssl/www_wnimg_nl.key'            => { content => $::role_waarneming::conf::www_wnimg_nl_key },
    '/etc/nginx/ssl'                             => { source       => 'puppet:///modules/role_waarneming/nginx_ssl',
                                                      recurse      => true, },
  },
  $sites = {
    '/etc/nginx/sites-enabled/default'                   => { source => 'puppet:///modules/role_waarneming/nginx_sites/default' },
    '/etc/nginx/sites-enabled/observado.org'             => { source => 'puppet:///modules/role_waarneming/nginx_sites/observado.org' },
    '/etc/nginx/sites-enabled/observation.org'           => { source => 'puppet:///modules/role_waarneming/nginx_sites/observation.org' },
    '/etc/nginx/sites-enabled/observations.be'           => { source => 'puppet:///modules/role_waarneming/nginx_sites/observations.be' },
    '/etc/nginx/sites-enabled/waarneming.nl'             => { source => 'puppet:///modules/role_waarneming/nginx_sites/waarneming.nl' },
    '/etc/nginx/sites-enabled/waarnemingen.be'           => { source => 'puppet:///modules/role_waarneming/nginx_sites/waarnemingen.be' },
    '/etc/nginx/sites-enabled/waarnemingen.nl'           => { source => 'puppet:///modules/role_waarneming/nginx_sites/waarnemingen.nl' },
    '/etc/nginx/sites-enabled/wnimg'                     => { source => 'puppet:///modules/role_waarneming/nginx_sites/wnimg' },
    '/etc/nginx/sites-enabled/project.waarnemingen.be'   => { source => 'puppet:///modules/role_waarneming/nginx_sites/project.waarnemingen.be' },
    '/etc/nginx/sites-enabled/beta.waarneming.nl'        => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.waarneming.nl' },
    '/etc/nginx/sites-enabled/noordzee.waarneming.nl'    => { source => 'puppet:///modules/role_waarneming/nginx_sites/noordzee.waarneming.nl' },
    '/etc/nginx/sites-enabled/beta.waarnemingen.be'      => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.waarnemingen.be' },
    '/etc/nginx/sites-enabled/beta.observations.be'      => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.observations.be' },
    '/etc/nginx/sites-enabled/beta.observation.org'      => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.observation.org' },
    '/etc/nginx/sites-enabled/beta.observado.org'        => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.observado.org' },
    '/etc/nginx/sites-available/offline'                 => { source => 'puppet:///modules/role_waarneming/nginx_sites/offline' },
    '/etc/nginx/sites-enabled/beta.waarneming-test.nl'   => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.waarneming-test.nl' },
    '/etc/nginx/sites-enabled/beta.waarneming-acc.nl'    => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.waarneming-acc.nl' },
    '/etc/nginx/sites-enabled/beta.waarnemingen-test.be' => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.waarnemingen-test.be' },
    '/etc/nginx/sites-enabled/beta.waarnemingen-acc.be'  => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.waarnemingen-acc.be' },
    '/etc/nginx/sites-enabled/beta.observation-test.org' => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.observation-test.org' },
    '/etc/nginx/sites-enabled/beta.observation-acc.org ' => { source => 'puppet:///modules/role_waarneming/nginx_sites/beta.observation-acc.org' },
    '/etc/nginx/sites-enabled/waarneming-test.nl'        => { source => 'puppet:///modules/role_waarneming/nginx_sites/waarneming-test.nl' },
    '/etc/nginx/sites-enabled/waarneming-acc.nl'         => { source => 'puppet:///modules/role_waarneming/nginx_sites/waarneming-acc.nl' },
    '/etc/nginx/sites-enabled/waarnemingen-test.be '     => { source => 'puppet:///modules/role_waarneming/nginx_sites/waarnemingen-test.be' },
    '/etc/nginx/sites-enabled/waarnemingen-acc.be '      => { source => 'puppet:///modules/role_waarneming/nginx_sites/waarnemingen-acc.be' },
    '/etc/nginx/sites-enabled/observation-test.org '     => { source => 'puppet:///modules/role_waarneming/nginx_sites/observation-test.org' },
    '/etc/nginx/sites-enabled/observation-acc.org'       => { source => 'puppet:///modules/role_waarneming/nginx_sites/observation-acc.org' },
  }
) {
  # Defaults for all file resources
  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['nginx'],
    require => Package['nginx'],
  }

  # SSL certs and keys for sites
  create_resources(file, $certs_and_keys, $defaults)

  # Nginx site config files, verbatim
  create_resources(file, $sites, $defaults)

  file { '/etc/nginx/sites-enabled/offline':
    ensure => absent,
  }
}
