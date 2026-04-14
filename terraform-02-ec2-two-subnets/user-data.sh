#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y nginx

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /usr/share/nginx/html/index.html <<EOF
<h1>Terraform Example 02</h1>
<p>Role: Multi-instance EC2 deployment</p>
<p>Name Prefix: ${name_prefix}</p>
<p>Server Name: ${server_name}</p>
<p>Instance ID: $${INSTANCE_ID}</p>
<p>Availability Zone: $${AVAILABILITY_ZONE}</p>
EOF

systemctl enable nginx
systemctl restart nginx
