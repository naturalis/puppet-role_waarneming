server {
    listen 443 ssl;
    server_name         project.waarnemingen-test.be;
    ssl_certificate	    /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/waarnemingen.be/privkey.pem;
    include include/pfs.conf;
    include include/common-site-config-project.conf;
}

server {
    listen 80;
    server_name project.waarnemingen-test.be;
    rewrite ^ https://$host$request_uri? permanent;
}
