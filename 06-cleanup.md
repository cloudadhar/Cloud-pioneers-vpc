# Cloud Pioneers Cleanup

Cleanup order matters because resources have dependencies and time-based charges.

## Delete First

1. Optional EC2 Instance Connect Endpoint (stretch task)
2. NAT Gateway, if created; wait until it is deleted
3. NAT Gateway Elastic IP after deletion completes

## Remove Remaining Workshop Resources

- Terminate `web-server-public` and `app-server-private`; wait until both are terminated.
- Delete `cloud-pioneers-vpc`. Deleting the VPC also removes its subnets, route tables, Internet Gateway attachment, and Security Groups.
- Delete any key pairs or Security Groups created by mistake outside the workshop VPC.

## Verification

- No workshop EC2 instance is running or stopped in `ap-south-1`.
- No NAT Gateway remains in a billable state.
- No allocated Elastic IP remains.
- No EC2 Instance Connect Endpoint remains.
- No workshop VPC remains.
- No workshop resources remain in another Region.
- A Zero spend budget is active for future practice.

Verify resource names and IDs before deletion. Never delete the default VPC or resources you did not create in this workshop.
