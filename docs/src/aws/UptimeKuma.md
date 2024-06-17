# Uptime Kuma

An off-site uptime monitoring solution hosted on AWS ECS.

> [uptime.kgb33.dev](https://uptime.kgb33.dev/)

# Pulumi Steps

Secrets required:
  - Cloudflare token (with write access to `kgb33.dev`) as `CLOUDFLARE_API_TOKEN`
  - Allow Pulumi access to AWS (See [here](https://www.pulumi.com/docs/clouds/aws/get-started/begin/#configure-pulumi-to-access-your-aws-account)

AWS Permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "acm:DeleteCertificate",
                "acm:DescribeCertificate",
                "acm:ListTagsForCertificate",
                "acm:RequestCertificate",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:CreateTags",
                "ec2:DeleteSecurityGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:DetachRolePolicy",
                "iam:GetRole",
                "iam:ListInstanceProfilesForRole",
                "iam:ListRolePolicies",
                "logs:DeleteLogGroup",
                "logs:ListTagsLogGroup"
            ],
            "Resource": "*"
        }
    ]
}
```

Then just `pulumi up` and navigate to [uptime.kgb33.dev](https://uptime.kgb33.dev)
