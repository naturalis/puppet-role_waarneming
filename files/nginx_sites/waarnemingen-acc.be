server {
    listen              443 ssl;
    server_name		    waarnemingen-acc.be;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen-acc.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen-acc.be/privkey.pem;
    include             include/pfs.conf;

    access_log          /var/log/nginx/waarnemingen-acc.be_access.log custom;
    error_log           /var/log/nginx/waarnemingen-acc.be_error.log;
    include             include/common-site-config-new.conf;
    include             include/phppgadmin.conf;
}

server {
    listen              443 ssl;
    server_name         *.waarnemingen-acc.be;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen-acc.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen-acc.be/privkey.pem;
    include             include/pfs.conf;

    access_log          /var/log/nginx/waarnemingen-acc.be_access.log custom;
    error_log           /var/log/nginx/waarnemingen-acc.be_error.log;
    include             include/common-site-config.conf;
    include             include/phppgadmin.conf;
}

server {
    listen              80;
    server_name         waarnemingen-acc.be *.waarnemingen-acc.be;
    access_log          /var/log/nginx/waarnemingen-acc.be_nossl_access.log custom;
    error_log           /var/log/nginx/waarnemingen-acc.be_nossl_error.log;

    location / {
       return 301 https://$host$request_uri;
    }

    include include/non-ssl-obsmapp.conf;
}

server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen.be/privkey.pem;

    server_name acc.waarnemingen.be;
    return 301 https://waarnemingen-acc.be$request_uri;
}
