# Part 1 Challenge - Build the VPC Foundation

## Objective

Create the two-AZ network foundation that Part 2 will use to host a public web tier and a private application tier.

## Use

- Region `ap-south-1`
- Amazon VPC `10.0.0.0/16` named `cloud-pioneers-vpc` with DNS hostnames enabled
- Two Availability Zones
- Two public and two private `/24` subnets from the workshop IP plan
- Internet Gateway `cloud-pioneers-igw`
- Main, `public-rt`, and `private-rt` route tables
- VPC Resource Map

## Build Sequence

1. Create the VPC with **VPC only**, so every component is built and understood separately.
2. Create the four subnets in the correct Availability Zones.
3. Enable auto-assign public IPv4 on the two public subnets only.
4. Create and attach the Internet Gateway.
5. Create `public-rt` with `0.0.0.0/0 -> cloud-pioneers-igw` and associate both public subnets.
6. Create `private-rt` with the local route only and associate both private subnets.
7. Open the VPC Resource Map and verify the wiring.

## Constraints

- public-subnet-a and public-subnet-b must use a route table with `0.0.0.0/0` targeting the Internet Gateway.
- private-subnet-a and private-subnet-b must remain local-only.
- Every subnet must have an explicit intended route-table association.
- Enable public IPv4 assignment only on public subnets.
- Do not create EC2 instances, NAT Gateways, or Elastic IPs in Part 1.
- Resource identifiers must be discovered dynamically; never copy IDs from screenshots.

## Required Proof

- VPC Resource Map showing four subnets across two Availability Zones
- CIDR table with total and AWS-usable addresses
- Public route table and subnet associations
- Private route table and subnet associations
- Main route table retained as a local-only fallback
- Internet Gateway attachment
- Explanation of what makes a subnet public or private

## Validation Questions

- Are all four `/24` ranges inside `10.0.0.0/16` and non-overlapping?
- Do only the public subnets receive the IGW default route?
- Are public IPv4 settings aligned with actual routing?
- Before step 5, were the "public" subnets actually public? Why not?
- Can you identify the route that wins for internal VPC traffic and explain longest-prefix match?

## Carry Forward

Keep the VPC for the Part 2 challenge. If you stop here, complete [06-cleanup.md](./06-cleanup.md).
