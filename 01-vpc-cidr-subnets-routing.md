# Part 1 - VPC, CIDR, Subnets, and Routing

Goal: Understand the network building blocks before creating resources.

## Core Story

> A VPC is your private network in one AWS Region. A subnet is a slice of that
> network that lives in one Availability Zone. A route table decides where
> traffic goes. An Internet Gateway is the door to the internet.

## Key Concepts

| Concept | Meaning |
|---|---|
| Region | Geographic area with multiple isolated Availability Zones, such as `ap-south-1` |
| Availability Zone | One or more independent data centers inside a Region |
| VPC | A logically isolated virtual network in one AWS Region |
| Subnet | A VPC CIDR range that belongs to one Availability Zone |
| CIDR | Address range plus network prefix, such as `10.0.0.0/16` |
| Route table | Destination-and-target rules that select a traffic path |
| Local route | Automatic route for communication inside the VPC CIDR |
| Internet Gateway | Highly available VPC gateway targeted by internet routes |
| Main route table | Fallback route table for subnets without explicit association |

## Scope Rules

- A VPC is regional.
- A subnet belongs to exactly one Availability Zone.
- A VPC can have only one Internet Gateway attached.
- A route table can be associated with multiple subnets; a subnet has exactly one route table.
- Every VPC has a main route table.
- A default VPC and a main route table are different concepts.

## CIDR Planning

AWS IPv4 VPC and subnet CIDRs can range from `/16` through `/28`. Subnet CIDRs
must fit inside the VPC CIDR and must not overlap.

```text
Total IPv4 addresses = 2^(32 - prefix)
AWS usable subnet addresses = total - 5
```

| CIDR | Total IPv4 | AWS usable |
|---|---:|---:|
| `/16` | 65,536 | 65,531 |
| `/20` | 4,096 | 4,091 |
| `/24` | 256 | 251 |
| `/26` | 64 | 59 |
| `/28` | 16 | 11 |

For `10.0.1.0/24`, AWS reserves:

| Address | Purpose |
|---|---|
| `10.0.1.0` | Network address |
| `10.0.1.1` | VPC router |
| `10.0.1.2` | Amazon-provided DNS |
| `10.0.1.3` | Future use |
| `10.0.1.255` | Network broadcast address; broadcast is unsupported |

Use private (RFC 1918) ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
Avoid overlapping CIDRs. Overlap blocks or complicates later VPC Peering,
Transit Gateway, VPN, and on-premises connectivity.

## AWS Subnet Calculator

Use the [AWS Subnet Calculator](https://www.awssubnetcalculator.com/) as an
optional visual planning and verification tool.

For this lab:

1. Enter the VPC CIDR `10.0.0.0/16`.
2. Plan four `/24` subnets.
3. Compare the generated ranges with the workshop IP plan below.
4. Confirm that every subnet is inside the VPC CIDR.
5. Confirm that no subnet ranges overlap.

## Workshop IP Plan

| Resource | CIDR | Scope | Purpose |
|---|---|---|---|
| cloud-pioneers-vpc | `10.0.0.0/16` | Region | Network boundary |
| public-subnet-a | `10.0.1.0/24` | AZ A | Web tier |
| public-subnet-b | `10.0.2.0/24` | AZ B | Web tier (future HA) |
| private-subnet-a | `10.0.11.0/24` | AZ A | App tier |
| private-subnet-b | `10.0.12.0/24` | AZ B | App / data tier (future HA) |

Each `/24` subnet has 256 total and 251 usable IPv4 addresses. Public subnets
use `1.x`, private subnets use `11.x`, leaving room for future tiers such as
`21.x` for databases.

## Public and Private Subnets

A subnet name does not make it public or private.

| Route table | Routes | Associated subnets |
|---|---|---|
| public-rt | local + `0.0.0.0/0 -> IGW` | public-subnet-a, public-subnet-b |
| private-rt | local only | private-subnet-a, private-subnet-b |
| Main | local only | No intended lab subnet |

A subnet is public when its route table has a route to an Internet Gateway. For
IPv4 internet communication, an instance also needs a public IPv4 or Elastic
IP and applicable Security Group rules.

## Route Selection

When multiple routes match, AWS uses longest-prefix match: the most specific
destination wins.

- `10.0.0.0/16 -> local` is more specific than `0.0.0.0/0 -> IGW` for VPC
  addresses, so internal traffic always stays inside the VPC.
- `0.0.0.0/0` means all IPv4 destinations.
- The local route cannot be deleted.

## Public IPv4 Behavior

| Address | Important behavior |
|---|---|
| Private IPv4 | Used inside the VPC and stays with the instance through stop/start |
| EC2 public IPv4 | Can change after stop/start and returns to the Amazon pool |
| Elastic IP | Persistent public IPv4 that can be reassociated |

The instance never sees its public IPv4 on its network interface. The Internet
Gateway translates between public and private IPv4.

## Important Distinction

Route tables provide reachability. Security groups and NACLs filter traffic. A
valid route does not automatically mean traffic is allowed.

## Check Your Understanding

1. What makes a subnet public?
2. How many usable IPv4 addresses does an AWS `/24` subnet provide?
3. Why should you design for two Availability Zones?
4. Does enabling auto-assign public IPv4 add an IGW route?
5. Which route wins for `10.0.11.25`: `10.0.0.0/16` or `0.0.0.0/0`?
