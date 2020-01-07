server {
    listen              443 ssl;
    server_name         waarnemingen.be mijntuinlab.waarnemingen.be stagbeetle.waarnemingen.be;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen.be/privkey.pem;
    include             include/pfs.conf;
    access_log          /var/log/nginx/waarnemingen.be_access.log custom;
    error_log           /var/log/nginx/waarnemingen.be_error.log;
    include             include/common-site-config-new.conf;
    include             include/custom-error-page.conf;
    include             include/phppgadmin.conf;
}

server {
    listen              443 ssl;
    server_name         *.waarnemingen.be;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen.be/privkey.pem;
    include             include/pfs.conf;
    access_log          /var/log/nginx/waarnemingen.be_access.log custom;
    error_log           /var/log/nginx/waarnemingen.be_error.log;
    include             include/common-site-config.conf;
    include             include/phppgadmin.conf;
}


server {
    listen              80;
    server_name         waarnemingen.be *.waarnemingen.be;
    access_log          /var/log/nginx/waarnemingen.be_nossl_access.log custom;
    error_log           /var/log/nginx/waarnemingen.be_nossl_error.log;

    location / {
        return 301 https://$host$request_uri;
    }

    include             include/non-ssl-obsmapp.conf;
}
