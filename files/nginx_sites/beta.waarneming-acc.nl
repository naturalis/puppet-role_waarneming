server {
    listen 80;
    listen		443 ssl;
    server_name		beta.waarneming-acc.nl;

    ssl_certificate	/etc/letsencrypt/live/waarneming-acc.nl/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/waarneming-acc.nl/privkey.pem;
    include include/pfs.conf;

    rewrite ^ https://waarneming-acc.nl$request_uri? permanent;
}
