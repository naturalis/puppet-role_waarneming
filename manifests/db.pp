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
  }
) {
  # Generate required locales
  class { 'locales':
    default_locale => 'en_US.UTF-8',
    locales        => ['af_ZA.UTF-8 UTF-8', 'am_ET.UTF-8 UTF-8', 'be_BY.UTF-8 UTF-8', 'bg_BG.UTF-8 UTF-8', 'crh_UA.UTF-8 UTF-8', 'cs_CZ.UTF-8 UTF-8', 'da_DK.UTF-8 UTF-8', 'de_DE.UTF-8 UTF-8', 'el_GR.UTF-8 UTF-8', 'en_AG.UTF-8 UTF-8', 'en_AU.UTF-8 UTF-8', 'en_BW.UTF-8 UTF-8', 'en_CA.UTF-8 UTF-8', 'en_DK.UTF-8 UTF-8', 'en_GB.UTF-8 UTF-8', 'en_HK.UTF-8 UTF-8', 'en_IE.UTF-8 UTF-8', 'en_IN.UTF-8 UTF-8', 'en_NG.UTF-8 UTF-8', 'en_NZ.UTF-8 UTF-8', 'en_PH.UTF-8 UTF-8', 'en_SG.UTF-8 UTF-8', 'en_US.UTF-8 UTF-8', 'en_ZA.UTF-8 UTF-8', 'en_ZM.UTF-8 UTF-8', 'en_ZW.UTF-8 UTF-8', 'es_ES.UTF-8 UTF-8', 'et_EE.UTF-8 UTF-8', 'fr_CH.UTF-8 UTF-8', 'fr_FR.UTF-8 UTF-8', 'he_IL.UTF-8 UTF-8', 'hu_HU.UTF-8 UTF-8', 'hy_AM.UTF-8 UTF-8', 'it_IT.UTF-8 UTF-8', 'ja_JP.UTF-8 UTF-8', 'lt_LT.UTF-8 UTF-8', 'nl_NL.UTF-8 UTF-8', 'pl_PL.UTF-8 UTF-8', 'pt_PT.UTF-8 UTF-8', 'ro_RO.UTF-8 UTF-8', 'ru_RU.UTF-8 UTF-8', 'ru_UA.UTF-8 UTF-8', 'sl_SI.UTF-8 UTF-8', 'sv_SE.UTF-8 UTF-8', 'tr_TR.UTF-8 UTF-8', 'uk_UA.UTF-8 UTF-8']
  }

  # Install PostgreSQL
  class { '::postgresql::globals':
    manage_package_repo => true,
    version             => $::role_waarneming::conf::postgresql_version,
  }->
  class { '::postgresql::server': }
  class { '::postgresql::server::postgis': }

  # Create postgresql database
  ::postgresql::server::database { $::role_waarneming::conf::postgresql_dbname:
    require  => Class['postgresql::server'],
  }

  # Create postgresql users
  create_resources('::postgresql::server::role', $roles)
}

