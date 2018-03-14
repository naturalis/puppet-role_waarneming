server {
    listen		443 ssl;
    server_name		noordzee.waarneming.nl noordzee-acc.waarneming.nl noordzee-test.waarneming.nl;
    ssl_certificate	/etc/nginx/ssl/waarneming_nl-chained.crt;
    ssl_certificate_key	/etc/nginx/ssl/waarneming_nl.key;

    #include include/block_ip.conf;

    location @uwsgi {
    uwsgi_pass  unix:///var/uwsgi/noordzee.socket;
        include uwsgi_params;
    }

    location / {
        if ($request_method = POST) { return 404; }
        if ($http_cookie ~* "no_fpc") { return 404; }
        default_type  "text/html; charset=utf-8";
        set $memcached_key "fpc:$scheme://$host$request_uri";
        memcached_pass localhost:11211;
        error_page     404 405 502 504 = @uwsgi;
    }

    location /robots.txt {
    alias /home/noordzee/static/robots.txt;
    }

    location /favicon.ico {
    alias /home/noordzee/static/img/icon/favicon.ico;
    }

    location /static/ {
    alias /home/noordzee/static/;
    }

    location /media/ {
    alias /home/noordzee/media/;
    }

}

server {
    listen 80;
    server_name		noordzee.waarneming.nl noordzee-acc.waarneming.nl noordzee-test.waarneming.nl;
    rewrite ^ https://$host$request_uri? permanent;
}
