server {
    listen		443 ssl;
    server_name project-test.waarnemingen.be;
    ssl_certificate	     /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key	 /etc/letsencrypt/live/waarnemingen.be/privkey.pem;

    include include/common-site-config-new.conf;
}

server {
    listen 80;
    server_name project-test.waarnemingen.be;
    rewrite ^ https://$host$request_uri? permanent;
}
