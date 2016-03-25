# All configurable settings
class role_waarneming::conf (
  # ::web
  $waarneming_key,
  $waarneming_crt,
  $waarneming_server_name = '_',
  $observation_key,
  $observation_crt,
  $observation_server_name = '.observation.org',
  $wnimg_key,
  $wnimg_crt,
  $wnimg_server_name = '.wnimg.nl',
  $git_repo_key,
  $git_repo_url = 'ssh://git@bitbucket.org/zostera/waarneming.git',
  $git_repo_url = 'master',

  # ::db
  $postgresql_dbname   = 'waarneming',
  $postgresql_version  = '9.5',
  $waarneming_password,
  $local_be_password,
  $local_nl_password,
  $local_xx_password,
) {
  # Configure apt to apt-get update once a day
  class { 'apt':
    update => {
      frequency => 'daily',
    },
  }
}
