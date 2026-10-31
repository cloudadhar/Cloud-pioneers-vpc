# Cloud Pioneers - Design a Real-World VPC and Deploy an Application on EC2

AWS Hands-On Builders Workshop - AWS Student Builder Group x CloudAdhar<br>
This workshop builds and validates a production-style two-tier network on AWS. Learners design a two-AZ VPC, prove what makes a subnet public or private, deploy a web application on EC2 in a public subnet, and reach an application server in a private subnet that the internet cannot reach directly.



## Start Here

| Seq | Session | Focus | File |
|---:|---|---|---|
| 01 | Part 1 | VPC, CIDR, subnets, and routing | [01-vpc-cidr-subnets-routing.md](./01-vpc-cidr-subnets-routing.md) |
| 02 | Part 1 | Build the VPC foundation | [02-vpc-foundation-lab.md](./02-vpc-foundation-lab.md) |
| 03 | Part 2 | Security Groups, EC2, user data, and the two-tier pattern | [03-security-groups-and-ec2.md](./03-security-groups-and-ec2.md) |
| 04 | Part 2 | Deploy the web app and validate the private tier | [04-ec2-web-app-lab.md](./04-ec2-web-app-lab.md) |
| 05 | Both | Document the final architecture | [05-architecture-exercise.md](./05-architecture-exercise.md) |
| 06 | End | Remove billable resources safely | [06-cleanup.md](./06-cleanup.md) |

## Classroom Standard

Region: Asia Pacific (Mumbai) `ap-south-1`. Resource IDs, AMI IDs, account IDs, and public/private host addresses must be discovered dynamically.

| Resource | CIDR | Purpose |
|---|---|---|
| cloud-pioneers-vpc | `10.0.0.0/16` | Workshop VPC |
| public-subnet-a | `10.0.1.0/24` | Web server in AZ A |
| public-subnet-b | `10.0.2.0/24` | Public tier in AZ B (future ALB / second web server) |
| private-subnet-a | `10.0.11.0/24` | Private app server in AZ A |
| private-subnet-b | `10.0.12.0/24` | Private tier in AZ B (future app server / database) |

| Component | Name |
|---|---|
| Internet Gateway | `cloud-pioneers-igw` |
| Route tables | `public-rt`, `private-rt` |
| Security Groups | `web-sg`, `app-sg` |
| EC2 instances | `web-server-public`, `app-server-private` |
| User data (both instances) | [`scripts/user-data-demo.sh`](./scripts/user-data-demo.sh) - Cloud Pioneers VPC Demo page |
| User data (alternative) | [`scripts/user-data-web.sh`](./scripts/user-data-web.sh), [`scripts/user-data-private.sh`](./scripts/user-data-private.sh) |

## Required Outcomes

- Explain why a subnet name does not make it public, and what does.
- Explain the Internet -> Internet Gateway -> public route table -> Security Group -> EC2 path.
- Deploy nginx on EC2 with user data and open the application over HTTP.
- Prove the app server has no public IPv4 and is reachable only from the web tier.
- Use a Security Group reference (`web-sg` -> `app-sg`) instead of an IP-based rule.
- Prove one controlled Security Group rejection and its recovery.
- Explain why a NAT Gateway is needed for private outbound internet, and what it costs.
- Delete every workshop resource and confirm nothing billable remains.

## Cost and Safety Rules

- VPCs, subnets, route tables, Internet Gateways, and Security Groups have no charge.
- EC2, EBS, and public IPv4 can create charges; use only Free Tier eligible `t2.micro` or `t3.micro` and terminate after the session.
- NAT Gateway and Elastic IP are not free. The NAT Gateway is a trainer demo only; learners do not create it.
- Do not open SSH to `0.0.0.0/0`. Use EC2 Instance Connect with the AWS-managed Instance Connect prefix list as the only SSH source.
- Do not create key pairs for this workshop.
- Create a Zero spend budget before starting if your account does not have one.
- Never publish credentials, account IDs, billing details, or unredacted sensitive output in screenshots or posts.

<div align="center">

[YouTube](https://youtube.com/@cloudadhar) | [Instagram](https://instagram.com/cloudadhar) | [LinkedIn](https://linkedin.com/in/gangadharure)

CloudAdhar - Building Cloud Futures

</div>
