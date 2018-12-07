server {
    listen 443 ssl;
    server_name old.waarneming-test.nl;

    ssl_certificate /etc/nginx/ssl/waarneming-test.nl/fullchain1.pem;
    ssl_certificate_key /etc/nginx/ssl/waarneming-test.nl/privkey1.pem;
    include include/pfs.conf;

    access_log /var/log/nginx/old.waarneming-test.nl_access.log custom;
    error_log /var/log/nginx/old.waarneming-test.nl_error.log;

    include include/common-site-config.conf;
    include include/phppgadmin.conf;
}

server {
    listen 80;
    server_name old.waarneming-test.nl;
    return 301 https://$host$request_uri;
}
