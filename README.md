# Cloud Pioneers - Design a Real-World VPC & Deploy an Application on EC2

AWS Hands-On Builders Workshop - AWS Student Builder Group x CloudAdhar<br>

Build a two-AZ VPC with public and private subnets, an Internet Gateway and a NAT Gateway, deploy a web application on EC2 in the public subnet, and prove that the server in the private subnet cannot be reached from the internet.


## Before You Start

- AWS account (Free Tier is fine)
- Region: **Asia Pacific (Mumbai) `ap-south-1`** (top-right corner of the console)
- No SSH keys or software needed - only a browser

## IP Plan

| Resource | Name | CIDR | AZ |
|---|---|---|---|
| VPC | `cloud-pioneers-vpc` | `10.0.0.0/16` | - |
| Public subnet | `public-subnet-a` | `10.0.1.0/24` | ap-south-1a |
| Public subnet | `public-subnet-b` | `10.0.2.0/24` | ap-south-1b |
| Private subnet | `private-subnet-a` | `10.0.11.0/24` | ap-south-1a |
| Private subnet | `private-subnet-b` | `10.0.12.0/24` | ap-south-1b |

A `/24` subnet has 256 addresses; AWS reserves 5, so 251 are usable.

## Key Concepts

| Concept | Meaning |
|---|---|
| VPC | Your private network in one AWS Region |
| Subnet | A part of the VPC that lives in one Availability Zone |
| Internet Gateway (IGW) | Two-way door between the VPC and the internet |
| NAT Gateway | One-way door out: private subnets can reach the internet, the internet cannot reach them |
| Route table | Rules that decide where traffic goes |
| Public subnet | Its route table has `0.0.0.0/0 -> IGW` |
| Private subnet | No route to the IGW (outbound goes via NAT) |
| Security Group | Stateful firewall on the instance (allow rules only) |

> A subnet is public **only** because its route table points to the Internet Gateway - not because of its name.

## All Steps at a Glance

| Step | What you create |
|---:|---|
| 1 | VPC |
| 2 | Subnets (2 public, 2 private) |
| 3 | Enable auto-assign public IP on public subnets |
| 4 | Internet Gateway (create + attach) |
| 5 | NAT Gateway (in a public subnet) |
| 6 | Route tables (public -> IGW, private -> NAT) + subnet associations |
| 7 | Security groups |
| 8 | EC2 in the private subnet |
| 9 | EC2 in the public subnet |
| 10 | Test public vs private |
| 11 | Break it and fix it |
| 12 | Cleanup |

---

## Step 1 - Create the VPC

1. Console -> **VPC** -> **Your VPCs** -> **Create VPC**
2. Resources to create: **VPC only**
3. Name tag: `cloud-pioneers-vpc`
4. IPv4 CIDR: `10.0.0.0/16`
5. **Create VPC**
6. Select the VPC -> **Actions -> Edit VPC settings** -> tick **Enable DNS hostnames** -> **Save**

## Step 2 - Create the Subnets

1. **Subnets** -> **Create subnet** -> VPC ID: `cloud-pioneers-vpc`
2. Add all 4 subnets (use **Add new subnet** for each):

| Subnet name | Availability Zone | IPv4 subnet CIDR |
|---|---|---|
| `public-subnet-a` | ap-south-1a | `10.0.1.0/24` |
| `public-subnet-b` | ap-south-1b | `10.0.2.0/24` |
| `private-subnet-a` | ap-south-1a | `10.0.11.0/24` |
| `private-subnet-b` | ap-south-1b | `10.0.12.0/24` |

3. **Create subnet**

## Step 3 - Enable Auto-Assign Public IP (Public Subnets Only)

For `public-subnet-a` and `public-subnet-b`:

1. Select the subnet -> **Actions -> Edit subnet settings**
2. Tick **Enable auto-assign public IPv4 address** -> **Save**

Do **not** do this for the private subnets.

## Step 4 - Create and Attach the Internet Gateway

1. **Internet gateways** -> **Create internet gateway**
2. Name tag: `cloud-pioneers-igw` -> **Create**
3. **Actions -> Attach to VPC** -> `cloud-pioneers-vpc` -> **Attach internet gateway**

## Step 5 - Create the NAT Gateway

> NAT Gateway is **not free** (charged per hour + per GB, plus its Elastic IP). Delete it at the end (Step 12).

1. **NAT gateways** -> **Create NAT gateway**
2. Name: `cloud-pioneers-nat`
3. Subnet: **`public-subnet-a`** (a NAT Gateway must be in a public subnet)
4. Connectivity type: **Public**
5. Click **Allocate Elastic IP**
6. **Create NAT gateway** -> wait until the state is **Available** (1-2 minutes)

## Step 6 - Create Route Tables and Associate Subnets

### Public route table

1. **Route tables** -> **Create route table**
2. Name: `public-rt` - VPC: `cloud-pioneers-vpc` -> **Create**
3. **Routes** tab -> **Edit routes** -> **Add route**: Destination `0.0.0.0/0` -> Target **Internet Gateway** -> `cloud-pioneers-igw` -> **Save**
4. **Subnet associations** tab -> **Edit subnet associations** -> tick `public-subnet-a` and `public-subnet-b` -> **Save**

### Private route table

1. **Route tables** -> **Create route table**
2. Name: `private-rt` - VPC: `cloud-pioneers-vpc` -> **Create**
3. **Routes** tab -> **Edit routes** -> **Add route**: Destination `0.0.0.0/0` -> Target **NAT Gateway** -> `cloud-pioneers-nat` -> **Save**
4. **Subnet associations** tab -> **Edit subnet associations** -> tick `private-subnet-a` and `private-subnet-b` -> **Save**

| Route table | Routes | Subnets |
|---|---|---|
| `public-rt` | `10.0.0.0/16 -> local`, `0.0.0.0/0 -> IGW` | public-subnet-a, public-subnet-b |
| `private-rt` | `10.0.0.0/16 -> local`, `0.0.0.0/0 -> NAT Gateway` | private-subnet-a, private-subnet-b |

Check: open `cloud-pioneers-vpc` -> **Resource map** tab.


Leave outbound rules as default. `app-sg` trusts `web-sg`, not an IP address - only the web server can reach the app server.

## Step 7 - Launch EC2 in the Public Subnet

Same as Step 8, with these changes:

| Setting | Value |
|---|---|
| Name | `web-server-public` |
| Subnet | `public-subnet-a` |
| Create Security Group | `pioneers-vpc-sg` |
| Auto-assign public IP | **Enable** |
| Firewall | `web-sg` |
| User data | the same script |

<details>
<summary><b>User data script (click to expand)</b> - same script for both instances, also in <a href="./scripts/user-data-demo.sh">scripts/user-data-demo.sh</a></summary>

```bash
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

if [ "$EGRESS" = "true" ]; then INTERNET="Allowed"; else INTERNET="Blocked"; fi

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
      Private IP: $PRIVATE_IP &nbsp;|&nbsp; Public IP: $PUBLIC_IP<br>
      Outbound internet: $INTERNET
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
```

</details>


**Launch instance** -> wait 1-2 minutes after **Running** -> copy its **Public IPv4 address**.

## Step 8 - Launch EC2 in the Private Subnet

**EC2** -> **Launch instances**

| Setting | Value |
|---|---|
| Name | `app-server-private` |
| AMI | Amazon Linux 2023 |
| Instance type | `t2.micro` or `t3.micro` (Free Tier eligible) |
| Key pair | Proceed without a key pair |
| Network settings -> **Edit** -> VPC | `cloud-pioneers-vpc` |
| Subnet | `private-subnet-a` |
| Auto-assign public IP | **Disable** |
| Firewall | Select existing security group -> `app-sg` |
| Advanced details -> User data | paste the script below |

**Launch instance** -> note its **Private IPv4 address**.

## Step 10 - Test: Public vs Private

| Test | Open in your browser | Result |
|---|---|---|
| 1 | `http://<web-public-ip>` | Works - page shows **PUBLIC SUBNET** |
| 2 | `http://<app-private-ip>:8080` | Blocked - no public IP, no route from the internet |
| 3 | `http://<web-public-ip>/probe/<app-private-ip>/` | Works - page shows **PRIVATE SUBNET**, reached through the web server |

> Use `http://`, not `https://`.

On the private page, **Outbound internet: Allowed** - that is the NAT Gateway. The private server can reach out, but the internet still cannot reach in (test 2).

## Step 11 - Break It and Fix It

| Change | What happens | Why |
|---|---|---|
| Remove the 8080 rule from `app-sg` | Test 3 shows `504 Gateway Time-out` | Security Group blocks web -> app |
| Associate `public-subnet-a` with `private-rt` | Test 1 stops loading | No route to the IGW = no longer public |

Put both back and everything works again.

## Step 12 - Cleanup

Delete in this order:

1. **EC2** -> terminate `web-server-public` and `app-server-private` -> wait for **Terminated**
2. **NAT gateways** -> select `cloud-pioneers-nat` -> **Actions -> Delete** -> wait for **Deleted**
3. **Elastic IPs** -> select the NAT's Elastic IP -> **Actions -> Release**
4. **Your VPCs** -> select `cloud-pioneers-vpc` -> **Actions -> Delete VPC** (removes subnets, route tables, IGW and security groups)
5. Check that **Instances**, **NAT gateways** and **Elastic IPs** are empty

Optional: **Billing -> Budgets -> Zero spend budget** for future practice.

## Troubleshooting

| Problem | Check |
|---|---|
| Page does not load | `http://` not `https://`, `web-sg` port 80, subnet uses `public-rt` |
| No public IP | Auto-assign public IP was disabled at launch |
| Default nginx page | User data missing - check `/var/log/cloud-init-output.log` |
| Test 3 fails | Correct private IP? `app-sg` allows 8080 from `web-sg`? |
| Outbound internet: Blocked on private page | NAT not **Available** yet, or `private-rt` missing `0.0.0.0/0 -> NAT` when the instance launched |
| Resources missing | Wrong Region - switch to Mumbai `ap-south-1` |

## Learn More

- [What is Amazon VPC?](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [NAT gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [EC2 user data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)

<div align="center">

[YouTube](https://youtube.com/@cloudadhar) | [Instagram](https://instagram.com/cloudadhar) | [LinkedIn](https://linkedin.com/in/gangadharure)

CloudAdhar - Building Cloud Futures

</div>
