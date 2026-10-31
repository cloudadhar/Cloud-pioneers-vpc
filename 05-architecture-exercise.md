# Cloud Pioneers Architecture Exercise

Create an editable diagram showing the learner build and label the production extensions separately.


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

