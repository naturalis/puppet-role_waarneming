server {
    listen              443 ssl;
    server_name         waarnemingen-test.be;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen-test.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen-test.be/privkey.pem;
    include             include/pfs.conf;

    access_log          /var/log/nginx/waarnemingen-test.be_access.log custom;
    error_log           /var/log/nginx/waarnemingen-test.be_error.log;
    include             include/common-site-config-new.conf;
    include             include/phppgadmin.conf;
}

server {
    listen              443 ssl;
    server_name         *.waarnemingen-test.be;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen-test.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen-test.be/privkey.pem;
    include             include/pfs.conf;

    access_log          /var/log/nginx/waarnemingen-test.be_access.log custom;
    error_log           /var/log/nginx/waarnemingen-test.be_error.log;
    include             include/common-site-config.conf;
    include             include/phppgadmin.conf;
}

server {
    listen              80;
    server_name         waarnemingen-test.be *.waarnemingen-test.be;
    access_log          /var/log/nginx/waarnemingen-test.be_nossl_access.log custom;
    error_log           /var/log/nginx/waarnemingen-test.be_nossl_error.log;

    location / {
       return 301 https://$host$request_uri;
    }

    include             include/non-ssl-obsmapp.conf;
}

server {
    listen              80;
    listen              443 ssl;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen.be/privkey.pem;
    server_name         test.waarnemingen.be;

    return 301 https://waarnemingen-test.be$request_uri;
}
