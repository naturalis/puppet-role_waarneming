server {
    listen		443 ssl;
    server_name		waarneming.nl noordzee.waarneming.nl nederlandzoemt.waarneming.nl;
    ssl_certificate /etc/letsencrypt/live/waarneming.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming.nl/privkey.pem;
    include include/pfs.conf;
    access_log		/var/log/nginx/waarneming.nl_access.log custom;
    error_log		/var/log/nginx/waarneming.nl_error.log;
    include include/common-site-config-new.conf;
    include include/custom-error-page.conf;
    include include/phppgadmin.conf;
}

server {
    listen      443 ssl;
    server_name     *.waarneming.nl;
    ssl_certificate /etc/letsencrypt/live/waarneming.nl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/waarneming.nl/privkey.pem;
    include include/pfs.conf;
    access_log      /var/log/nginx/waarneming.nl_access.log custom;
    error_log       /var/log/nginx/waarneming.nl_error.log;
    include include/common-site-config.conf;
    include include/phppgadmin.conf;
}

server {
    listen		80;
    server_name		waarneming.nl *.waarneming.nl;
    access_log		/var/log/nginx/waarneming.nl_nossl_access.log custom;
    error_log		/var/log/nginx/waarneming.nl_nossl_error.log;
    location / {
	   return 301 https://$host$request_uri;
    }
    include include/non-ssl-obsmapp.conf;
}
