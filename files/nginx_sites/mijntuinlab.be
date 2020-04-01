server {
    listen              443 ssl;
    server_name         mijntuinlab.be www.mijntuinlab.be acc.mijntuinlab.be test.mijntuinlab.be;
    ssl_certificate     /etc/letsencrypt/live/mijntuinlab.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mijntuinlab.be/privkey.pem;
    include             include/pfs.conf;
    access_log          /var/log/nginx/mijntuinlab.be_access.log custom;
    error_log           /var/log/nginx/mijntuinlab.be_error.log;
    include             include/common-site-config-new.conf;
    include             include/custom-error-page.conf;
}

server {
    listen              80;
    server_name         mijntuinlab.be www.mijntuinlab.be acc.mijntuinlab.be test.mijntuinlab.be;
    access_log          /var/log/nginx/mijntuinlab.be_access.log custom;
    error_log           /var/log/nginx/mijntuinlab.be_error.log;

    location / {
        return 301 https://$host$request_uri;
    }
}
