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
  $git_repo_key_php,
  $git_repo_key_django,
  $git_repo_url_php        = 'ssh://git@bitbucket.org/zostera/waarneming.git',
  $git_repo_url_django     = 'ssh://git@bitbucket.org/zostera/obs.git',
  $git_repo_rev_php        = 'master',
  $git_repo_rev_django     = 'master',
  $nginx_allow_ip          = ['1.1.1.1','2.2.2.2'],

  # ::db
  $db_host            = '127.0.0.1',
  $db_name            = 'waarneming',
  $postgresql_version = '9.5',
  $pgbouncer_port     = 5432,
  $waarneming_password,
  $local_be_password,
  $local_nl_password,
  $local_xx_password,
  $local_00_password,
  $hisko_password,
  $hugo_password,
  $obs_password,
  $analytics_password,
) {
  # Define postgres version and add postgres apt repo
  class { '::postgresql::globals':
    manage_package_repo => true,
    version             => $postgresql_version,
    postgis_version     => '2.3',
  }
}
