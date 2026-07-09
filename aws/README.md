AWS
===


```
                   Internet
                       │
                Internet Gateway
                       │
                 Public Subnet
                       │
     ┌────────────┬────────────┬────────────┐
     │            │            │
   EC2 #1      EC2 #2      EC2 #3 ... EC2 #N
     │            │            │
     └────────────┴────────────┘
           Security Group
          (all instances can
         communicate internally)
                 │
         IAM Instance Profile
                 │
             Shared S3 Bucket
```



