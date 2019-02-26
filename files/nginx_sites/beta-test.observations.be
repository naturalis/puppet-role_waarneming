server {
    listen		443 ssl;
    server_name beta-test.observations.be;
    ssl_certificate	/etc/letsencrypt/live/observations.be/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/observations.be/privkey.pem;
    include include/pfs.conf;

    include include/common-site-config-new.conf;
}

server {
    listen 80;
    server_name beta-test.observations.be;
    rewrite ^ https://$host$request_uri? permanent;
}
