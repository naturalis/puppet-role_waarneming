server {
    listen		443 ssl;
    server_name		waarnemingen-test.be *.waarnemingen-test.be;
    ssl_certificate /etc/nginx/ssl/waarnemingen-test.be/fullchain1.pem;
    ssl_certificate_key /etc/nginx/ssl/waarnemingen-test.be/privkey1.pem;
    include include/pfs.conf;
    keepalive_timeout	60;
    access_log		/var/log/nginx/waarnemingen-test.be_access.log custom;
    error_log		/var/log/nginx/waarnemingen-test.be_error.log;

    include include/common-site-config.conf;
    include include/phppgadmin.conf;
}

server {
    listen		80;
    server_name		waarnemingen-test.be *.waarnemingen-test.be;
    access_log		/var/log/nginx/waarnemingen-test.be_nossl_access.log custom;
    error_log		/var/log/nginx/waarnemingen-test.be_nossl_error.log;

    location / {
	return 301 https://$host$request_uri;
    }

    include include/non-ssl-obsmapp.conf;
}
