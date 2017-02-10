# Install and configure PostgreSQL
class role_waarneming::db (
  $roles = {
    'waarneming'      => {
      'superuser'     => true,
      'password_hash' => postgresql_password('waarneming', $::role_waarneming::conf::waarneming_password),
    },
    'local_be'        => {
      'superuser'     => true,
      'password_hash' => postgresql_password('local_be', $::role_waarneming::conf::local_be_password),
    },
    'local_nl'        => {
      'superuser'     => true,
      'password_hash' => postgresql_password('local_nl', $::role_waarneming::conf::local_nl_password),
    },
    'local_xx'        => {
      'superuser'     => true,
      'password_hash' => postgresql_password('local_xx', $::role_waarneming::conf::local_xx_password),
    },
    'local_00'        => {
      'superuser'     => true,
      'password_hash' => postgresql_password('local_00', $::role_waarneming::conf::local_00_password),
    },
    'hisko'           => {
      'superuser'     => true,
      'password_hash' => postgresql_password('hisko', $::role_waarneming::conf::hisko_password),
    },
    'hugo'            => {
      'superuser'     => true,
      'password_hash' => postgresql_password('hugo', $::role_waarneming::conf::hugo_password),
    },
    'obs'             => {
      'superuser'     => true,
      'password_hash' => postgresql_password('obs', $::role_waarneming::conf::obs_password),
    },
  },
  $config_entries = {
    'max_connections'           => {value => 150},
    'shared_buffers'            => {value => '16GB'},
    'effective_cache_size'      => {value => '56GB'},
    'max_stack_depth'           => {value => '7680kB'},
    'temp_buffers'              => {value => '16MB'},
    'work_mem'                  => {value => '16MB'},
    'maintenance_work_mem'      => {value => '2GB'},
    'sort_mem'                  => {value => '64MB'},
    'random_page_cost'          => {value => 2},
    'track_activity_query_size' => {value => 8192},
  }
) {
  # Generate required locales
  class { 'locales':
    default_locale => 'en_US.UTF-8',
    locales        => [
      'af_ZA.UTF-8 UTF-8', 'am_ET.UTF-8 UTF-8', 'ar_MA.UTF-8 UTF-8', 'az_AZ.UTF-8 UTF-8',
      'be_BY.UTF-8 UTF-8', 'bg_BG.UTF-8 UTF-8', 'bs_BA.UTF-8 UTF-8', 'ca_ES.UTF-8 UTF-8',
      'crh_UA.UTF-8 UTF-8', 'cs_CZ.UTF-8 UTF-8', 'da_DK.UTF-8 UTF-8', 'de_DE.UTF-8 UTF-8',
      'el_GR.UTF-8 UTF-8', 'en_AG.UTF-8 UTF-8', 'en_AU.UTF-8 UTF-8', 'en_BW.UTF-8 UTF-8',
      'en_CA.UTF-8 UTF-8', 'en_DK.UTF-8 UTF-8', 'en_GB.UTF-8 UTF-8', 'en_HK.UTF-8 UTF-8',
      'en_IE.UTF-8 UTF-8', 'en_IN.UTF-8 UTF-8', 'en_NG.UTF-8 UTF-8', 'en_NZ.UTF-8 UTF-8',
      'en_PH.UTF-8 UTF-8', 'en_SG.UTF-8 UTF-8', 'en_US.UTF-8 UTF-8', 'en_ZA.UTF-8 UTF-8',
      'en_ZM.UTF-8 UTF-8', 'en_ZW.UTF-8 UTF-8', 'es_ES.UTF-8 UTF-8', 'et_EE.UTF-8 UTF-8',
      'fa_IR.UTF-8 UTF-8', 'fr_CH.UTF-8 UTF-8', 'fr_FR.UTF-8 UTF-8', 'fy_NL.UTF-8 UTF-8',
      'he_IL.UTF-8 UTF-8', 'hu_HU.UTF-8 UTF-8', 'hr_HR.UTF-8 UTF-8', 'hy_AM.UTF-8 UTF-8',
      'it_IT.UTF-8 UTF-8', 'ja_JP.UTF-8 UTF-8', 'ka_GE.UTF-8 UTF-8', 'lt_LT.UTF-8 UTF-8',
      'lv_LV.UTF-8 UTF-8', 'mk_MK.UTF-8 UTF-8', 'nl_NL.UTF-8 UTF-8', 'nb_NO.UTF-8 UTF-8',
      'pap_AN.UTF-8 UTF-8', 'pl_PL.UTF-8 UTF-8', 'pt_PT.UTF-8 UTF-8', 'ro_RO.UTF-8 UTF-8',
      'ru_RU.UTF-8 UTF-8', 'ru_UA.UTF-8 UTF-8', 'sl_SI.UTF-8 UTF-8', 'sq_AL.UTF-8 UTF-8',
      'sr_RS.UTF-8 UTF-8', 'sv_SE.UTF-8 UTF-8', 'tr_TR.UTF-8 UTF-8', 'uk_UA.UTF-8 UTF-8'
    ]
  }

  # Install PostgreSQL
  class { '::postgresql::server':
    listen_addresses => "localhost,${$::role_waarneming::conf::db_host}",
    require          => Class['postgresql::globals']
  }

  class { '::postgresql::server::postgis': }

  # Multiple performance enhancing tweaks based on previous production setup
  create_resources('::postgresql::server::config_entry', $config_entries)

  # Create postgresql database
  ::postgresql::server::database { $::role_waarneming::conf::db_name: }

  # Create postgresql users
  create_resources('::postgresql::server::role', $roles)

  # If conf::web_host is an IP (and not a hostname or CIDR range) add /32
  if (is_ip_address($::role_waarneming::conf::web_host)) and ($::role_waarneming::conf::web_host !~ /\d+\/\d{1,2}$/) {
    $web_host = "${$::role_waarneming::conf::web_host}/32"
  } else {
    $web_host = $::role_waarneming::conf::web_host
  }

  ::postgresql::server::pg_hba_rule { 'allow app host(s) to access database':
    description => "Open up PostgreSQL for access from ${$web_host}",
    type        => 'host',
    database    => 'all',
    user        => 'all',
    address     => $web_host,
    auth_method => 'md5',
    before      => Class['postgresql::server::reload']
  }
}
