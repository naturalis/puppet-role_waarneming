server {
    listen		443 ssl;
    server_name		beta.waarnemingen-acc.be;

    ssl_certificate	/etc/letsencrypt/live/waarnemingen-acc.be/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/waarnemingen-acc.be/privkey.pem;
    include include/pfs.conf;

    include include/common-site-config-new.conf;
    include include/custom-error-page.conf;
}

server {
    listen 80;
    server_name beta.waarnemingen-acc.be;
    return 301 https://beta.waarnemingen-acc.be$request_uri;
}

server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen.be/privkey.pem;

    server_name beta-acc.waarnemingen.be;
    return 301 https://beta.waarnemingen-acc.be$request_uri;
}
