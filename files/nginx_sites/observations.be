server {
    listen		*:443 ssl;
    server_name		observations.be www.observations.be acc.observations.be test.observations.be localhost.observations.be;

    ssl_certificate /etc/nginx/ssl/observations.be/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/observations.be/privkey.pem;
    include include/pfs.conf;

    keepalive_timeout	60;
    access_log		/var/log/nginx/observations.be_access.log custom;
    error_log		/var/log/nginx/observations.be_error.log;

    include		include/common-site-config.conf;
}

server {
    listen		*:80;
    server_name		observations.be www.observations.be acc.observations.be test.observations.be;
    access_log		/var/log/nginx/observations.be_access.log custom;
    error_log		/var/log/nginx/observations.be_error.log;

    location / {
	return 301 https://$host$request_uri;
    }
}
