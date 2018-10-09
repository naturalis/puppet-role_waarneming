server {
    listen		443 ssl;
    server_name		waarneming.nl *.waarneming.nl;

    ssl_certificate /etc/nginx/ssl/waarneming.nl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/waarneming.nl/privkey.pem;
    include include/pfs.conf;

    keepalive_timeout	60;
    access_log		/var/log/nginx/waarneming.nl_access.log custom;
    error_log		/var/log/nginx/waarneming.nl_error.log;

    include include/common-site-config.conf;
    include include/phppgadmin.conf;
}

server {
    listen		80;
    server_name		waarneming.nl *.waarneming.nl;
    access_log		/var/log/nginx/waarneming.nl_nossl_access.log custom;
    error_log		/var/log/nginx/waarneming.nl_nossl_error.log;

    location / {
	return 301 https://$host$request_uri;
    }

    include include/non-ssl-obsmapp.conf;
}
