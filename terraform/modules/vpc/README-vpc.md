### Notes on VPC subnet routing

- CIDR Block explained: a typical VPC defines a large CIDR block, usually 10.0.0.0/16.
    - The CIDR syntax - think of it as 4 groups of 8 bits, the 16 is how many bits are locked. So, in this VPC example, the IPs will all start be '10.0.x.x'. 
    - If 10.0.0.0/16 is your dev deployment, then 10.1.0.0/16 can be your prod.
- All the subnets need to live inside the subnet of that VPC. So basically, lock the first 24 bits and define the 3rd block number. Example: (region in parentheses)
    - public subnet 1 (2a) 10.0.0.0/24
    - public subnet 2 (2b) 10.0.1.0/24
    - private subnet 1 (2a) 10.0.10.0/24
    - private subnet 2 (2b) 10.0.11.0/24
