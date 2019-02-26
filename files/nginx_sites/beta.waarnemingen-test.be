server {
    listen		443 ssl;
    server_name		beta.waarnemingen-test.be;

    ssl_certificate	/etc/letsencrypt/live/waarnemingen-test.be/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/waarnemingen-test.be/privkey.pem;
    include include/pfs.conf;

    include include/common-site-config-new.conf;
}

server {
    listen 80;
    server_name beta.waarnemingen-test.be;
    return 301 https://beta.waarnemingen-test.be$request_uri;
}


server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen.be/privkey.pem;

    server_name beta-test.waarnemingen.be;
    return 301 https://beta.waarnemingen-test.be$request_uri;
}
