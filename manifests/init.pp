# nginx
class nginx (
  $image                 = 'nginx',
  $version               = '1.14.2',
  $container_name        = 'nginx',
  $docker_ports          = ['80:80'],
  $network,
  $install_dir           = '/opt/nginx',
  $cert_dir              = '/opt/nginx/sslcert',
  $log_dir               = '/var/log/nginx',
  $monitoring_enabled    = false,
  $monitoring_status_url = '/server_status',
) {
  $nginx_uid = 104
  $nginx_gid = 107
  $conf_dir  = "${install_dir}/conf.d"

  file { $install_dir :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0655',
  }
  -> file { $conf_dir :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0655',
  }
  -> file { $cert_dir :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0655',
  }
  -> file { $log_dir :
    ensure => directory,
    owner  => $nginx_uid,
    group  => $nginx_gid,
    mode   => '0655',
  }

  file { "${conf_dir}/000_params.conf" :
    ensure  => present,
    owner   => $nginx_uid,
    group   => $nginx_gid,
    mode    => '0644',
    source  => 'puppet:///modules/nginx/conf/params.conf',
    require => File[$conf_dir],
    notify  => Docker::Run['nginx'],
  }
  file { "${conf_dir}/100_localhost.conf" :
    ensure  => present,
    owner   => $nginx_uid,
    group   => $nginx_gid,
    mode    => '0644',
    content => template('nginx/conf/localhost.conf.erb'),
    require => File[$conf_dir],
    notify  => Docker::Run['nginx'],
  }
  file { "${conf_dir}/100_monitoring.conf" :
    ensure  => $monitoring_enabled ? {
      true    => present,
      default => absent
    },
    owner   => $nginx_uid,
    group   => $nginx_gid,
    mode    => '0644',
    content => template('nginx/conf/monitoring.conf.erb'),
    require => File[$conf_dir],
    notify  => Docker::Run['nginx'],
  }

  if $monitoring_enabled {
    $_docker_ports = concat($docker_ports , ['127.0.0.1:81:81'])
  } else {
    $_docker_ports = $docker_ports
  }
  docker::run { $container_name :
    image    => "${image}:${version}",
    hostname => 'nginx',
    ports    => $_docker_ports,
    volumes  => [
      "${conf_dir}:/etc/nginx/conf.d",
      "${log_dir}:/var/log/nginx",
      "${cert_dir}:/etc/nginx/sslcert",
    ],
    net      => $network,
    require  => File[
      $install_dir,
      $cert_dir,
      $log_dir
    ]
  }

  file { "/etc/logrotate.d/${container_name}" :
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('nginx/logrotate/nginx.erb'),
  }
}
