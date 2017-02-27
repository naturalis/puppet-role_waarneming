#!/bin/bash
iostat -x -m -y 5 12 | awk '/vda/ { print strftime("%Y-%m-%dT%H:%M:%S"), $0; fflush(); }' >> /opt/postgresql/iostat.plain
