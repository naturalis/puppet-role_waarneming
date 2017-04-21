#!/usr/bin/env bash

SUDO="/usr/bin/sudo"

echo "disable puppet agent"
$SUDO /usr/bin/puppet agent --disable

echo "force php git repo refresh"
$SUDO -i -u waarneming /usr/bin/git -C /home/waarneming/www pull

echo "fix offline html files (negeer de foutmelding over index.html, dit is een dangling symlink)"
$SUDO /bin/sed -i -e 's/April [[:digit:]]\{1,2\}/April 24/' -e 's/[[:digit:]]\{1,2\} april/24 april/' -- *.html

echo "replace nginx vhosts with offline version"
$SUDO /bin/rm /etc/nginx/sites-enabled/*
$SUDO /bin/ln -s /etc/nginx/sites-available/offline /etc/nginx/sites-enabled/offline

echo "reload nginx"
$SUDO /usr/sbin/service nginx restart

echo "now run all actions and then enable puppet agent with: \"/usr/bin/puppet agent --enable\""
