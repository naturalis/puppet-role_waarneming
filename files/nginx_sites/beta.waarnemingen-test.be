server {
    listen		443 ssl;
    server_name		beta.waarnemingen-test.be;

    ssl_certificate	/etc/nginx/ssl/waarnemingen-test.be/fullchain1.pem;
    ssl_certificate_key	/etc/nginx/ssl/waarnemingen-test.be/privkey1.pem;
    include include/pfs.conf;

    #include include/block_ip.conf;

    location @uwsgi {
    uwsgi_pass  unix:///var/uwsgi/obs.socket;
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
    alias /home/obs/static/robots.txt;
    }

    location /favicon.ico {
    alias /home/obs/static/img/icon/favicon.ico;
    }

    location /static/ {
    alias /home/obs/static/;
    }

    location /media/ {
    alias /home/obs/media/;
    }

}

server {
    listen 80;
    server_name beta.waarnemingen-test.be;
    return 301 https://beta.waarnemingen-test.be$request_uri;
}


server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/waarnemingen.be/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/waarnemingen.be/privkey.pem;

    server_name beta-test.waarnemingen.be;
    return 301 https://beta.waarnemingen-test.be$request_uri;
}
