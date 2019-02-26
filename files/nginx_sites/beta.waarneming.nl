server {
    listen 80;
    listen		443 ssl;
    server_name beta.waarneming.nl;

    ssl_certificate /etc/letsencrypt/live/waarneming.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming.nl/privkey.pem;
    include include/pfs.conf;

    rewrite ^ https://waarneming.nl$request_uri? permanent;
}
