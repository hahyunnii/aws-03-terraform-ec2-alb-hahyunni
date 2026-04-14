#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y nginx

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /usr/share/nginx/html/index.html <<EOF
<h1>Terraform Example 03</h1>
<p>Role: ALB target instance</p>
<p>Name Prefix: ${name_prefix}</p>
<p>Server Name: ${server_name}</p>
<p>Instance ID: $${INSTANCE_ID}</p>
<p>Availability Zone: $${AVAILABILITY_ZONE}</p>
<p>App Port: ${app_port}</p>
EOF

# Move Nginx from port 80 to the custom application port used behind the ALB.
sed -i "s/listen       80;/listen       ${app_port};/" /etc/nginx/nginx.conf
sed -i "s/listen       \\[::\\]:80;/listen       [::]:${app_port};/" /etc/nginx/nginx.conf

systemctl enable nginx
systemctl restart nginx
