server {
    listen 80;
    listen 443 ssl;
    server_name	waarnemingen.nl *.waarnemingen.nl;
    access_log	/var/log/nginx/waarnemingen_nl_access.log;
    error_log	/var/log/nginx/waarnemingen_nl_error.log;
    rewrite  ^ https://waarneming.nl$request_uri? permanent;
}
