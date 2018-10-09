server {
    listen		443 ssl;
    server_name		waarnemingen.be *.waarnemingen.be;

    ssl_certificate /etc/nginx/ssl/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/waarnemingen.be/privkey.pem;
    include include/pfs.conf;

    keepalive_timeout	60;
    access_log		/var/log/nginx/waarnemingen.be_access.log custom;
    error_log		/var/log/nginx/waarnemingen.be_error.log;

    include include/common-site-config.conf;
}

server {
    listen		80;
    server_name		waarnemingen.be *.waarnemingen.be;
    access_log		/var/log/nginx/waarnemingen.be_nossl_access.log custom;
    error_log		/var/log/nginx/waarnemingen.be_nossl_error.log;

    location / {
	return 301 https://$host$request_uri;
    }

    include include/non-ssl-obsmapp.conf;
}
