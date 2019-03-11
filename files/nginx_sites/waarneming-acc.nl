server {
    listen		443 ssl;
    server_name		waarneming-acc.nl noordzee.waarneming-acc.nl nederlandzoemt.waarneming-acc.nl;
    ssl_certificate /etc/letsencrypt/live/waarneming-acc.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming-acc.nl/privkey.pem;
    include include/pfs.conf;
    access_log		/var/log/nginx/waarneming-acc.nl_access.log custom;
    error_log		/var/log/nginx/waarneming-acc.nl_error.log;
    include include/common-site-config-new.conf;
    include include/custom-error-page.conf;
    include include/phppgadmin.conf;
}

server {
    listen      443 ssl;
    server_name     *.waarneming-acc.nl;
    ssl_certificate /etc/letsencrypt/live/waarneming-acc.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming-acc.nl/privkey.pem;
    include include/pfs.conf;
    access_log      /var/log/nginx/waarneming-acc.nl_access.log custom;
    error_log       /var/log/nginx/waarneming-acc.nl_error.log;
    include include/common-site-config.conf;
    include include/phppgadmin.conf;
}

server {
    listen		80;
    server_name		waarneming-acc.nl *.waarneming-acc.nl;
    access_log		/var/log/nginx/waarneming-acc.nl_nossl_access.log custom;
    error_log		/var/log/nginx/waarneming-acc.nl_nossl_error.log;
    location / {
	   return 301 https://$host$request_uri;
    }
    include include/non-ssl-obsmapp.conf;
}

server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/waarneming.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming.nl/privkey.pem;
    server_name acc.waarneming.nl;
    return 301 https://waarneming-acc.nl$request_uri;
}
