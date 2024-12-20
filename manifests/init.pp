# Class: bind
#
# Install and enable an ISC BIND server.
#
# Parameters:
#  $chroot:
#   Enable chroot for the server. Default: false
#  $packagenameprefix:
#   Package prefix name. Default: 'bind' or 'bind9' depending on the OS
#
# Sample Usage :
#  include bind
#  class { 'bind':
#    chroot            => true,
#    packagenameprefix => 'bind97',
#  }
#
class bind (
  $chroot            = false,
  $service_reload    = true,
  $servicename       = $::bind::params::servicename,
  $packagenameprefix = $::bind::params::packagenameprefix,
  $binduser          = $::bind::params::binduser,
  $bindgroup         = $::bind::params::bindgroup,
  $bindlogdir        = $::bind::params::bindlogdir,
) inherits ::bind::params {

  # Chroot differences
  if $chroot == true {
    $packagenamesuffix = '-chroot'
    # Different service name with chroot on RHEL7+)
    if $facts['os']['family'] == 'RedHat' and
        versioncmp($facts['os']['release']['full'], '7') >= 0 {
      $servicenamesuffix = '-chroot'
    } else {
      $servicenamesuffix = ''
    }
  } else {
    $packagenamesuffix = ''
    $servicenamesuffix = ''
  }

  # Main package and service
  class { '::bind::package':
    packagenameprefix => $packagenameprefix,
    packagenamesuffix => $packagenamesuffix,
  }
  class { '::bind::service':
    servicename    => "${servicename}${servicenamesuffix}",
    service_reload => $service_reload,
  }

  # We want a nice log file which the package doesn't provide a location for
  file { $bindlogdir:
    ensure  => 'directory',
    owner   => $binduser,
    group   => $bindgroup,
    mode    => '0775',
    seltype => 'var_log_t',
    require => Class['::bind::package'],
    before  => Class['::bind::service'],
  }

  $bindlogsubdirs = [ 'client', 'config', 'database', 'default', 'general', 'lame-servers', 'network',
          'notify', 'queries', 'query-errors', 'rate-limit', 'resolver', 'security',
          'update', 'update-security', 'xfer-in', 'xfer-out' ]

  $bindlogsubdirs.each |String $bindlogsubdir| {
    file { "${bindlogdir}/${bindlogsubdir}":
      ensure  => 'directory',
      owner   => $binduser,
      group   => $bindgroup,
      mode    => '0775',
      seltype => 'var_log_t',
      require => Class['::bind::package'],
      before  => Class['::bind::service'],
    }
  }
}
