server {
    listen		443 ssl;
    server_name		waarnemingen-acc.be *.waarnemingen-acc.be;
    ssl_certificate /etc/nginx/ssl/waarnemingen-acc.be/fullchain1.pem;
    ssl_certificate_key /etc/nginx/ssl/waarnemingen-acc.be/privkey1.pem;
    keepalive_timeout	60;
    access_log		/var/log/nginx/waarnemingen-acc.be_access.log custom;
    error_log		/var/log/nginx/waarnemingen-acc.be_error.log;

    include include/common-site-config.conf;
    include include/phppgadmin.conf;
}

server {
    listen		80;
    server_name		waarnemingen-acc.be *.waarnemingen-acc.be;
    access_log		/var/log/nginx/waarnemingen-acc.be_nossl_access.log custom;
    error_log		/var/log/nginx/waarnemingen-acc.be_nossl_error.log;

    location / {
	return 301 https://$host$request_uri;
    }

    include include/non-ssl-obsmapp.conf;
}
