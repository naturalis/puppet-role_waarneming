server {
    listen 443 ssl;
    server_name old.waarneming.nl;

    ssl_certificate /etc/nginx/ssl/waarneming.nl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/waarneming.nl/privkey.pem;
    include include/pfs.conf;

    access_log /var/log/nginx/old.waarneming.nl_access.log custom;
    error_log /var/log/nginx/old.waarneming.nl_error.log;

    include include/common-site-config.conf;
    include include/phppgadmin.conf;
}

server {
    listen 80;
    server_name old.waarneming.nl;
    return 301 https://$host$request_uri;
}
