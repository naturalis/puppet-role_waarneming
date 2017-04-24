# crontab: 
# */1 * * * * /bin/bash /opt/postgresql/iostat.sh

#!/bin/bash
iostat -x -m -y 5 12 | awk '/vda|sda|sdb/ { print strftime("%Y-%m-%dT%H:%M:%S"), $0; fflush(); }' >> /var/log/postgresql/iostat.plain
