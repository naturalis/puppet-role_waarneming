server {
    listen 80;
    listen              443 ssl;
    server_name         project-test.waarnemingen.be;
    ssl_certificate     /etc/letsencrypt/live/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarnemingen.be/privkey.pem;
    rewrite ^ https://project.waarnemingen-test.be$request_uri? permanent;
}
