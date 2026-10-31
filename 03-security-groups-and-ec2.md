# Part 2 - Security Groups, EC2, User Data, and the Two-Tier Pattern

Goal: Understand how traffic is filtered, how an EC2 instance is bootstrapped,
and why real applications keep only the front door public.

## Core Story

> Routes decide where traffic can go. Security Groups decide what traffic is
> allowed. The web server lives in a public subnet and is the only door. The app
> server lives in a private subnet and only trusts the web server.

## Security Groups vs Network ACLs

| Characteristic | Security Group | Network ACL |
|---|---|---|
| Scope | Instance or ENI | Subnet |
| Rules | Allow only | Allow and deny |
| State | Stateful | Stateless |
| Return traffic | Automatically allowed | Must be allowed explicitly |
| Evaluation | All attached rules combine | Lowest matching rule number wins |
| New/default behavior | No inbound, allow outbound | Default NACL allows; custom starts deny-all |
| Best use | Primary workload firewall | Subnet guardrail or explicit deny |

This workshop keeps the default NACL and uses Security Groups as the workload
firewall.

## Workshop Security Groups

| Security Group | Inbound rule | Source | Reason |
|---|---|---|---|
| `web-sg` | TCP 80 | `0.0.0.0/0` | Public website |
| `web-sg` | TCP 22 | `com.amazonaws.ap-south-1.ec2-instance-connect` prefix list | Browser-based EC2 Instance Connect only |
| `app-sg` | TCP 8080 | `web-sg` | Only the web tier can call the app |
| `app-sg` | All ICMP - IPv4 | `web-sg` | Connectivity testing from the web tier |

Referencing a Security Group instead of an IP means any instance in `web-sg`
is trusted automatically. When the web tier scales from one instance to ten, no
rule changes.

## EC2 Launch Decisions

| Decision | Workshop choice | Why |
|---|---|---|
| AMI | Amazon Linux 2023 | Current AWS-maintained Linux; `dnf`, `python3`, and `curl` included |
| Instance type | `t2.micro` or `t3.micro` | Whichever the console marks Free Tier eligible |
| Key pair | None | EC2 Instance Connect pushes a short-lived key |
| Network | `cloud-pioneers-vpc`, explicit subnet | Never the default VPC |
| Public IPv4 | Web: enabled. App: disabled | Only the front door is public |
| Metadata | IMDSv2 | Token-based metadata access; the AL2023 default |

## User Data

User data is a script that runs once, as root, on the first boot.

| Script | Subnet | What it does | Needs internet? |
|---|---|---|---|
| [`user-data-demo.sh`](./scripts/user-data-demo.sh) | Both | Detects public or private subnet. Public: nginx on 80. Private: python3 on 8080, installs nothing. Shows the subnet type on a simple page | Only in the public subnet |
| [`user-data-web.sh`](./scripts/user-data-web.sh) | Public | Installs nginx and publishes a page showing the VPC, subnet, AZ, and IPs from IMDSv2 | Yes - `dnf install` via the IGW |
| [`user-data-private.sh`](./scripts/user-data-private.sh) | Private | Serves a page on TCP 8080 with the built-in `python3` | No |

The private script deliberately downloads nothing. The private subnet has no
route to the internet, so `dnf install` there would fail.

Bootstrap logs: `/var/log/cloud-init-output.log`

## The Two-Tier Request Path

```text
Browser -> Internet Gateway -> public-rt -> web-sg -> web-server-public (nginx :80)
        -> /private/ reverse proxy -> local route -> app-sg -> app-server-private (:8080)
```

The app server has no public IPv4 and no route to the Internet Gateway. The
internet cannot start a connection to it.

## NAT Gateway Preview

A private instance sometimes needs outbound internet access for patches, without
being reachable from the internet. A public NAT Gateway lives in a public subnet,
uses an Elastic IP, and the private route table sends `0.0.0.0/0` to it.

| Design | Result |
|---|---|
| No NAT (learner build) | Private tier has no internet access; zero NAT cost |
| One NAT in AZ A (trainer demo) | Outbound internet for private subnets; single-AZ dependency |
| One NAT per AZ with same-AZ routing | Resilient production design; two hourly charges |

NAT Gateway has hourly and per-GB data-processing charges. Check current AWS
pricing; delete the demo NAT Gateway and release its Elastic IP immediately.

## Key Decisions

1. Public web tier: public subnet + public IPv4 + `web-sg` allows HTTP.
2. Private app tier: private subnet + no public IPv4 + `app-sg` trusts `web-sg` only.
3. Admin access: EC2 Instance Connect, no key pairs, no SSH from `0.0.0.0/0`.
4. Private outbound internet: NAT Gateway (paid) - not part of the learner build.
5. High availability next step: Application Load Balancer and instances in both AZs.

## Check Your Understanding

1. Why does the reply from the web server reach your browser without an outbound rule?
2. What is the advantage of `app-sg` referencing `web-sg` instead of `10.0.1.0/24`?
3. Why can the web server run `dnf install` but the app server cannot?
4. Where does a NAT Gateway live, and why there?
5. What breaks first if AZ A fails in this design, and how would you fix it?
