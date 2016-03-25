# All configurable settings
class role_waarneming::conf (
  # ::web
  $web_host                = '127.0.0.1',
  $waarneming_key,
  $waarneming_crt,
  $waarneming_server_name  = '_',
  $observation_key,
  $observation_crt,
  $observation_server_name = '.observation.org',
  $wnimg_key,
  $wnimg_crt,
  $wnimg_server_name       = '.wnimg.nl',
  $git_repo_key,
  $git_repo_url            = 'ssh://git@bitbucket.org/zostera/waarneming.git',
  $git_repo_rev            = 'master',

  # ::db
  $db_host            = '127.0.0.1',
  $db_name            = 'waarneming',
  $postgresql_version = '9.5',
  $pgbouncer_port     = 5432,
  $waarneming_password,
  $local_be_password,
  $local_nl_password,
  $local_xx_password,
) {
  # Define postgres version and add postgres apt repo
  class { '::postgresql::globals':
    manage_package_repo => true,
    version             => $postgresql_version,
  }
}
