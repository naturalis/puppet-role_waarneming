server {
    listen		*:443 ssl;
    server_name		observations.be www.observations.be;
    ssl_certificate	/etc/nginx/ssl/observations_be-chained.crt;
    ssl_certificate_key	/etc/nginx/ssl/observations_be.key;
    keepalive_timeout	60;
    access_log		/var/log/nginx/observations.be_access.log custom;
    error_log		/var/log/nginx/observations.be_error.log;

    include		include/common-site-config.conf;
}

server {
    listen		*:80;
    server_name		observations.be www.observations.be;
    access_log		/var/log/nginx/observations.be_access.log custom;
    error_log		/var/log/nginx/observations.be_error.log;

    location / {
	return 301 https://$host$request_uri;
    }
}
