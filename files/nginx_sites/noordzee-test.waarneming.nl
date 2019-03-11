server {
    listen		443 ssl;
    server_name noordzee-test.waarneming.nl;
    ssl_certificate	/etc/letsencrypt/live/waarneming.nl/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/waarneming.nl/privkey.pem;

    include include/common-site-config-new.conf;
}

server {
    listen 80;
    server_name noordzee-test.waarneming.nl;
    rewrite ^ https://$host$request_uri? permanent;
}
