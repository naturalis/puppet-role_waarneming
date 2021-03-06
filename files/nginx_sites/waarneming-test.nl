server {
    listen              443 ssl;
    server_name         waarneming-test.nl noordzee.waarneming-test.nl bijentelling.waarneming-test.nl nederlandzoemt.waarneming-test.nl;
    ssl_certificate     /etc/letsencrypt/live/waarneming-test.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming-test.nl/privkey.pem;
    include             include/pfs.conf;

    access_log          /var/log/nginx/waarneming-test.nl_access.log custom;
    error_log           /var/log/nginx/waarneming-test.nl_error.log;
    include             include/common-site-config-new.conf;
    include             include/phppgadmin.conf;
}

server {
    listen              443 ssl;
    server_name         *.waarneming-test.nl;
    ssl_certificate     /etc/letsencrypt/live/waarneming-test.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming-test.nl/privkey.pem;
    include             include/pfs.conf;

    access_log          /var/log/nginx/waarneming-test.nl_access.log custom;
    error_log           /var/log/nginx/waarneming-test.nl_error.log;
    include             include/common-site-config.conf;
    include             include/phppgadmin.conf;
}

server {
    listen              80;
    server_name         waarneming-test.nl *.waarneming-test.nl;
    access_log          /var/log/nginx/waarneming-test.nl_nossl_access.log custom;
    error_log           /var/log/nginx/waarneming-test.nl_nossl_error.log;
    location / {
	   return 301 https://$host$request_uri;
    }
    include             include/non-ssl-obsmapp.conf;
}

server {
    listen              80;
    listen              443 ssl;
    ssl_certificate     /etc/letsencrypt/live/waarneming.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming.nl/privkey.pem;
    server_name         test.waarneming.nl;

    return 301 https://waarneming-test.nl$request_uri;
}
