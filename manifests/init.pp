class nginx (
  $image            = 'nginx',
  $version          = '1.11.3',
  $network,
  $install_dir      = '/opt/nginx',
  $cert_dir         = '/opt/nginx/sslcert',
  $log_dir          = '/var/log/nginx',
) {
  $nginx_uid        = 104
  $nginx_gid        = 107
  $conf_dir         = "${install_dir}/conf.d"

  file { "${install_dir}":
    ensure          => directory,
    owner           => root,
    group           => root,
    mode            => 655,
  } ->
  file { "${conf_dir}":
    ensure          => directory,
    owner           => root,
    group           => root,
    mode            => 655,
  } ->  
  file { "${cert_dir}":
    ensure          => directory,
    owner           => root,
    group           => root,
    mode            => 655,
  } ->
  file { "${log_dir}":
    ensure          => directory,
    owner           => "${nginx_uid}",
    group           => "${nginx_gid}",
    mode            => 655,
  }

  file { "${conf_dir}/0_params.conf" :
    ensure          => present,
    owner           => "${nginx_uid}",
    group           => "${nginx_gid}",
    mode            => 644,
    source          => "puppet:///modules/nginx/conf/params.conf",
    require         => File["${conf_dir}"],
    notify          => Docker::Run["nginx"], 
  }

  docker::run { 'nginx':
    image           => "${image}:${version}",
    hostname        => 'nginx',
    ports           => ['80:80', '443:443'],
    volumes         => [
      "${conf_dir}:/etc/nginx/conf.d",
      "${log_dir}:/var/log/nginx",
      "${cert_dir}:/etc/nginx/sslcert",
    ],
    net           => $network,
    require       => [File["${install_dir}"],
      File["${cert_dir}"], File["${log_dir}"]
    ]
  } 
}
