# Cloud Pioneers Architecture Exercise

Create an editable diagram showing the learner build and label the production extensions separately.

![Cloud Pioneers architecture](./assets/architecture.png)

## Required Boundaries and Components

- AWS Region `ap-south-1` and two Availability Zone boundaries
- `cloud-pioneers-vpc` `10.0.0.0/16` with its four `/24` subnets
- Internet Gateway
- `public-rt` and `private-rt` with their routes and associations
- `web-server-public` in `public-subnet-a` with `web-sg`
- `app-server-private` in `private-subnet-a` with `app-sg` and no public IPv4
- Security Group boundaries around each instance

## Traffic Flows to Draw

- Users -> Internet Gateway -> web-server-public (HTTP 80)
- web-server-public -> local route -> app-server-private (TCP 8080)
- No path from the internet directly to app-server-private

## Production Extension

Label these clearly as not part of the learner build:

- NAT Gateway in `public-subnet-a` with `private-rt` `0.0.0.0/0 -> NAT`
- One NAT Gateway per AZ with same-AZ routing
- Application Load Balancer across `public-subnet-a` and `public-subnet-b`
- Second web and app server in AZ B
- Database in the private tier with Multi-AZ

## Required Decision Notes

- Route tables select paths; Security Groups and NACLs filter traffic.
- A subnet is public only because its route table targets an Internet Gateway.
- Security Groups are stateful; NACLs are stateless.
- `app-sg` references `web-sg`, not an IP range.
- NAT Gateway gives outbound-only internet to private subnets and has hourly and data charges.

## Eraser Diagram-as-Code

Paste into [app.eraser.io](https://app.eraser.io) -> new Cloud Architecture diagram -> diagram-as-code panel.

```text
title Cloud Pioneers - Real-World VPC (ap-south-1)
direction right

Users [icon: users]

AWS Cloud [icon: aws] {
  Region ap-south-1 [icon: aws-region] {
    VPC 10.0.0.0/16 [icon: aws-vpc, color: green] {
      Internet Gateway [icon: aws-internet-gateway]

      AZ ap-south-1a [icon: aws-availability-zone, color: orange] {
        Public Subnet A 10.0.1.0/24 [icon: aws-public-subnet, color: green] {
          web-sg [icon: aws-security-group, color: red] {
            web-server-public [icon: aws-ec2]
          }
          NAT Gateway [icon: aws-nat-gateway]
        }
        Private Subnet A 10.0.11.0/24 [icon: aws-private-subnet, color: blue] {
          app-sg [icon: aws-security-group, color: red] {
            app-server-private [icon: aws-ec2]
          }
        }
      }

      AZ ap-south-1b [icon: aws-availability-zone, color: orange] {
        Public Subnet B 10.0.2.0/24 [icon: aws-public-subnet, color: green] {
          Future ALB [icon: aws-elastic-load-balancing]
        }
        Private Subnet B 10.0.12.0/24 [icon: aws-private-subnet, color: blue] {
          Future DB [icon: aws-rds]
        }
      }

      public-rt [icon: aws-route-table, color: green]
      private-rt [icon: aws-route-table, color: blue]
    }
  }
}

Users > Internet Gateway: HTTP 80
Internet Gateway > web-server-public
web-server-public > app-server-private: 8080 local route
app-server-private --> NAT Gateway: outbound only (production extension)
NAT Gateway --> Internet Gateway

public-rt -- Public Subnet A 10.0.1.0/24
public-rt -- Public Subnet B 10.0.2.0/24
private-rt -- Private Subnet A 10.0.11.0/24
private-rt -- Private Subnet B 10.0.12.0/24
```

Save an editable diagram and an exported image. Do not include account IDs, resource IDs, or public IPs.
