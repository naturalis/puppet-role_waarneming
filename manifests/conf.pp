# All configurable settings
class role_waarneming::conf (
  # ssh public keys
  $ssh_key_b1,
  $ssh_key_b2,
  $ssh_key_bt,
  $ssh_key_bh,
  $ssh_key_waarneming,
  $ssh_key_obs,
  $ssh_key_jieter,
  $ssh_key_hugo,
  $ssh_key_dylan,
  $ssh_key_folkert,
  $ssh_key_hisko,
  $ssh_key_sjaak,

  # ::php_app
  $git_repo_key_php,
  $git_repo_key_django,
  $git_repo_url_php                 = 'ssh://git@bitbucket.org/zostera/waarneming.git',
  $git_repo_url_scripts             = 'ssh://git@bitbucket.org/zostera/waarneming-scripts.git',
  $git_repo_url_django              = 'ssh://git@bitbucket.org/zostera/obs.git',
  $git_repo_ensure_php              = 'latest',
  $git_repo_ensure_django           = 'latest',
  $git_repo_rev_php                 = 'master',
  $git_repo_rev_scripts             = 'master',
  $git_repo_rev_django              = 'master',
  $scripts_send_mail                = false,
  $scripts_do_curl                  = false,
  $scripts_domain_prefix            = 'acc.',
  $php_ini_opcache_revalidate_freq  = '300',           # dev, test, acc = '5'
  $php_ini_display_errors           = 'Off',           # dev, test, acc = 'On',
  $obs_managesettings               = 'yes',           # dev = 'no'

  # ::php_app, ::vhost, not currently in use, can be ignored
  $waarneming_key          = nil,
  $waarneming_crt          = nil,
  $waarneming_server_name  = '_',
  $observation_key         = nil,
  $observation_crt         = nil,
  $observation_server_name = '.observation.org',
  $wnimg_key               = nil,
  $wnimg_crt               = nil,
  $wnimg_server_name       = '.wnimg.nl',

  # ::web, for direct copying of site configs
  $nginx_allow_ip = ['1.1.1.1','2.2.2.2'],
  $nginx_allow_user = {'user' => {'cryptpasswd' => 'xx'}, 'user2' => {'cryptpasswd' => 'yy'}},
  $waarneming_nl_crt,
  $waarneming_nl_key,
  $observation_org_crt,
  $observation_org_key,
  $observations_be_crt,
  $observations_be_key,
  $waarnemingen_be_crt,
  $waarnemingen_be_key,
  $www_wnimg_nl_crt,
  $www_wnimg_nl_key,
  $web_host_prod      = '127.0.0.1',
  $rsync_media        = false,
  $rsync_cron_weekday = 0,
  $rsync_cron_hour    = 1,
  $rsync_cron_minute  = 0,

  # ::db
  $web_host           = '127.0.0.1',
  $db_host            = '127.0.0.1',
  $phppgadmin_host    = '127.0.0.1',
  $db_slave_naturalis = '127.0.0.1',
  $db_slave_zostera   = '127.0.0.1',
  $db_slave_zostera2  = '127.0.0.1',
  $db_name            = 'waarneming',
  $postgresql_version = '9.6',
  $pgbouncer_port     = 5432,
  $waarneming_password,
  $local_be_password,
  $local_nl_password,
  $local_xx_password,
  $local_00_password,
  $hisko_password,
  $hugo_password,
  $obs_password,
  $obs_be_password,
  $analytics_password,
  $async_slave_password,
) {
  # Define postgres version and add postgres apt repo
  class { '::postgresql::globals':
    manage_package_repo => true,
    version             => $postgresql_version,
    postgis_version     => '2.3',
  }
}
