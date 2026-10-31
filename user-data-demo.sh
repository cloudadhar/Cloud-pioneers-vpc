#!/bin/bash
# =============================================================================
# Cloud Pioneers - VPC Demo web application (EC2 User Data, Amazon Linux 2023)
#
# Use the SAME script on both instances. It detects where it runs:
#   PUBLIC subnet  -> installs nginx, serves the page on port 80
#   PRIVATE subnet -> no internet, installs nothing, serves the page on
#                     port 8080 with the python3 built into Amazon Linux
#
# Demo:
#   http://<web-public-ip>                   -> works  (public subnet)
#   http://<app-private-ip>:8080             -> blocked from your laptop
#   http://<web-public-ip>/probe/<app-private-ip>/
#                                            -> works  (via web server, local route)
#
# Security groups: web-sg TCP 80 from 0.0.0.0/0 | app-sg TCP 8080 from web-sg
# =============================================================================

WEB_DIR=/var/www/cloud-pioneers
mkdir -p $WEB_DIR

# ---- Instance metadata (IMDSv2) ----------------------------------------------
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
md() { curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1" || echo "none"; }

INSTANCE_ID=$(md instance-id)
AZ=$(md placement/availability-zone)
PRIVATE_IP=$(md local-ipv4)
PUBLIC_IP=$(md public-ipv4)
MAC=$(md mac)
SUBNET_CIDR=$(md network/interfaces/macs/$MAC/subnet-ipv4-cidr-block)

# ---- Public or private? (public IP + internet access = public subnet) --------
EGRESS=false
for i in 1 2 3; do
  if curl -s -m 5 -o /dev/null https://aws.amazon.com; then EGRESS=true; break; fi
  sleep 3
done

if [ "$PUBLIC_IP" != "none" ] && [ "$EGRESS" = "true" ]; then
  SUBNET_TYPE="PUBLIC"
else
  SUBNET_TYPE="PRIVATE"
fi

# ---- Web page -----------------------------------------------------------------
cat > $WEB_DIR/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cloud Pioneers VPC Demo</title>
<style>
  body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
         background: #232F3E; color: #FFFFFF; font-family: "Amazon Ember", Arial, Helvetica, sans-serif; text-align: center; }
  h1 { font-size: 48px; margin: 0 0 12px; }
  h1 span { color: #FF9900; }
  p { font-size: 22px; margin: 0 0 32px; color: #D5DBDB; }
  .subnet { display: inline-block; background: #FF9900; color: #232F3E; font-weight: bold;
            font-size: 20px; padding: 12px 28px; border-radius: 6px; margin-bottom: 32px; }
  .info { font-size: 16px; color: #AAB7B8; line-height: 1.8; }
</style>
</head>
<body>
  <div>
    <h1><span>Cloud Pioneers</span> VPC Demo</h1>
    <p>Web application running from</p>
    <div class="subnet">$SUBNET_TYPE SUBNET &nbsp;$SUBNET_CIDR</div>
    <div class="info">
      Instance: $INSTANCE_ID<br>
      Availability Zone: $AZ<br>
      Private IP: $PRIVATE_IP &nbsp;|&nbsp; Public IP: $PUBLIC_IP
    </div>
  </div>
</body>
</html>
EOF

# ---- Start the web server ---------------------------------------------------------
if [ "$SUBNET_TYPE" = "PUBLIC" ]; then
  dnf install -y nginx
  cp $WEB_DIR/index.html /usr/share/nginx/html/index.html
  # /probe/10.0.x.x/ -> private server :8080 (only 10.0.0.0/16, no open proxy)
  cat > /etc/nginx/default.d/probe.conf <<'NGINX'
location ~ "^/probe/(10\.0\.[0-9]{1,3}\.[0-9]{1,3})/(.*)$" {
    proxy_pass http://$1:8080/$2;
    proxy_connect_timeout 4s;
    proxy_read_timeout 6s;
}
NGINX
  systemctl enable --now nginx
else
  cat > /etc/systemd/system/cloud-pioneers.service <<EOF
[Unit]
Description=Cloud Pioneers VPC Demo (port 8080)
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --directory $WEB_DIR
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now cloud-pioneers
fi
