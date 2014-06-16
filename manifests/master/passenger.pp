# Class puppet::master::passenger

class puppet::master::passenger (
  $host = $puppet::master::params::host,
  $passenger_max_pool_size      = $puppet::master::params::passenger_max_pool_size,
  $passenger_pool_idle_time     = $puppet::master::params::passenger_pool_idle_time,
  $passenger_stat_throttle_rate = $puppet::master::params::passenger_stat_throttle_rate,
  $passenger_max_requests       = $puppet::master::params::passenger_max_requests) inherits puppet::master::params {
  class { '::apache':
    mpm_module    => 'worker',
    default_vhost => false,
    serveradmin   => "webmaster@${::domain}",
    default_mods  => false,
  }

  if ($::lsbdistcodename == 'trusty') {
    ::apache::mod { 'access_compat': package_ensure => undef, }
    $custom_fragment = "  SSLCARevocationCheck chain\n  PassengerAppRoot /usr/share/puppet/rack/puppetmasterd\n  PassengerRoot /usr/lib/passenger"
  } else {
    $custom_fragment = "  PassengerAppRoot /usr/share/puppet/rack/puppetmasterd\n  PassengerRoot /usr/lib/passenger"
  }

  # passenger settings
  class { '::apache::mod::passenger':
    passenger_high_performance   => 'On',
    passenger_max_pool_size      => $passenger_max_pool_size,
    passenger_pool_idle_time     => $passenger_pool_idle_time,
    passenger_stat_throttle_rate => $passenger_stat_throttle_rate,
    passenger_max_requests       => $passenger_max_requests
  }

  apache::vhost { $host:
    docroot              => '/usr/share/puppet/rack/puppetmasterd/public/',
    docroot_owner        => 'root',
    docroot_group        => 'root',
    port                 => '8140',
    ssl                  => true,
    ssl_protocol         => 'ALL -SSLv2',
    ssl_cipher           => 'ALL:!aNULL:!eNULL:!DES:!3DES:!IDEA:!SEED:!DSS:!PSK:!RC4:!MD5:+HIGH:+MEDIUM:!LOW:!SSLv2:!EXP',
    ssl_honorcipherorder => 'on',
    ssl_cert             => "/var/lib/puppet/ssl/certs/${host}.pem",
    ssl_key              => "/var/lib/puppet/ssl/private_keys/${host}.pem",
    ssl_chain            => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_ca               => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_crl              => '/var/lib/puppet/ssl/ca/ca_crl.pem',
    ssl_certs_dir        => '/var/lib/puppet/ssl/certs',
    ssl_verify_client    => 'optional',
    ssl_verify_depth     => '1',
    ssl_options          => [
      '+StdEnvVars',
      '+ExportCertData'],
    rack_base_uris       => ['/'],
    directories          => [{
        path    => '/usr/share/puppet/rack/puppetmasterd/',
        options => 'None'
      }
      ],
    custom_fragment      => $custom_fragment,
    request_headers      => [
      'unset X-Forwarded-For',
      'set X-SSL-Subject %{SSL_CLIENT_S_DN}e',
      'set X-Client-DN %{SSL_CLIENT_S_DN}e',
      'set X-Client-Verify %{SSL_CLIENT_VERIFY}e',
      ],
    subscribe            => Class['puppet::master::install']
  }
}
