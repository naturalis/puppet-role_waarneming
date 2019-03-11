server {
    listen 80;
    listen		443 ssl;
    server_name		beta.waarneming-test.nl;

    ssl_certificate	/etc/letsencrypt/live/waarneming-test.nl/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/waarneming-test.nl/privkey.pem;
    include include/pfs.conf;

    rewrite ^ https://waarneming-test.nl$request_uri? permanent;
}
