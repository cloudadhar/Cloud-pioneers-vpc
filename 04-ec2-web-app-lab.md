# Part 2 Challenge - Deploy the Web App and Validate the Private Tier

## Objective

Deploy a web application on EC2 in the public subnet, deploy an application server in the private subnet, and prove that the private tier is reachable only through the web tier.

## Use

- `cloud-pioneers-vpc` from Part 1
- Security Groups `web-sg` and `app-sg`
- EC2 `web-server-public` in `public-subnet-a` and `app-server-private` in `private-subnet-a`
- One user data for both: [`scripts/user-data-demo.sh`](./scripts/user-data-demo.sh)
- Amazon Linux 2023, Free Tier eligible `t2.micro` or `t3.micro`
- EC2 Instance Connect
- nginx reverse proxy

## Build Sequence

Use the same user data on both instances: [`scripts/user-data-demo.sh`](./scripts/user-data-demo.sh). It detects whether it is in a public or private subnet and configures itself.

1. Create `web-sg` and `app-sg` using the rules in [03-security-groups-and-ec2.md](./03-security-groups-and-ec2.md).
2. Launch `app-server-private` in `private-subnet-a`, auto-assign public IPv4 **disabled**, user data `user-data-demo.sh`. Note its private IPv4.
3. Launch `web-server-public` in `public-subnet-a`, auto-assign public IPv4 **enabled**, the same user data.
4. Run the three access tests:

| Test | Open in your browser | Expected |
|---|---|---|
| 1 | `http://<web-public-ip>` | ✅ Page shows **PUBLIC SUBNET** |
| 2 | `http://<app-private-ip>:8080` | ❌ Never loads - no public IPv4, no IGW route |
| 3 | `http://<web-public-ip>/probe/<app-private-ip>/` | ✅ Page shows **PRIVATE SUBNET**, served through the web server |

5. Optional: from the web server (EC2 Instance Connect), run `curl -m 5 http://<app-private-ip>:8080` to see the same private page from inside the VPC.

![Public subnet page](./assets/demo-public-subnet.png)

<details>
<summary>Private subnet page (reached through the web server)</summary>

![Private subnet page](./assets/demo-private-subnet.png)

</details>

Alternative: [`user-data-web.sh`](./scripts/user-data-web.sh) and [`user-data-private.sh`](./scripts/user-data-private.sh) are simpler single-purpose scripts. With those, configure the `/private/` reverse proxy by hand from EC2 Instance Connect:

```bash
APP_IP=<app-server-private-ip>
curl http://$APP_IP:8080
echo "location /private/ { proxy_pass http://$APP_IP:8080/; }" | sudo tee /etc/nginx/default.d/private-app.conf
sudo nginx -t && sudo systemctl reload nginx
```

## Constraints

- Launch both instances in `cloud-pioneers-vpc`, never the default VPC.
- The app server must have no public IPv4.
- Do not create key pairs and do not allow SSH from `0.0.0.0/0`.
- `app-sg` must reference `web-sg`; do not use IP-based rules for the app tier.
- Do not install packages on the app server; it has no internet path.
- Do not create a NAT Gateway; it is a trainer demo only.
- Discover instance IDs, AMIs, and IP addresses at runtime.

## Required Proof

### Public web tier

- Browser showing the demo page with the PUBLIC SUBNET badge, subnet CIDR, AZ, private IP, and public IP
- `web-sg` inbound rules
- Explanation of why `ip addr` on the instance shows only the private IPv4

### Private app tier

- `app-server-private` details showing no public IPv4
- Test 2 blocked: the private IP cannot be opened from your laptop
- Test 3 allowed: the PRIVATE SUBNET page opened through the web server
- Explanation of the full request path from browser to private app

### Controlled failure

| Test | Expected result | Recovery |
|---|---|---|
| Remove the TCP 8080 rule from `app-sg` | Test 3 returns `504 Gateway Time-out` | Re-add the rule; works immediately |
| Associate `public-subnet-a` with `private-rt` | Website stops loading | Re-associate with `public-rt` |

Record what changed, what failed, and which control caused it.

## Failure Investigation

Record at least one issue and the order used to investigate it: Region, VPC selection, subnet association, route table, public IPv4, Security Group, application listener (`systemctl status nginx`), and bootstrap logs (`/var/log/cloud-init-output.log`).

| Symptom | Likely cause |
|---|---|
| Page does not load | `https://` instead of `http://`, missing port 80 rule, or subnet not public |
| No public IPv4 | Auto-assign public IPv4 disabled at launch |
| Default nginx page | User data not provided or failed |
| Instance Connect fails | Port 22 source is not the Instance Connect prefix list, or no public IPv4 |
| Test 3 blocked | `app-sg` missing 8080 from `web-sg`, wrong private IP, or private server still booting |

## Stretch

- Create an EC2 Instance Connect Endpoint in `private-subnet-a` and connect to the app server without a public IPv4. Confirm `curl -m 5 https://aws.amazon.com` times out from the private subnet.
- Watch the trainer's NAT Gateway demo and explain how the private route table changed.

## Cleanup

Complete [06-cleanup.md](./06-cleanup.md) immediately after capturing evidence.
