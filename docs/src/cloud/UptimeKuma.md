# Uptime Kuma

### [uptime.kgb33.dev](https://uptime.kgb33.dev/status/all)

An off-site uptime monitoring solution hosted on AWS ECS.

Scripts to deploy to both AWS and Fly.io exist in the repo; However, due to cost,
Uptime Kuma is only deployed to Fly.io. AWS documentation and Scrips are kept to
demonstrate AWS experience on a resume.

# Cloudflare Rules

Cloudflare (occasionally) tries to block this bot. 
To prevent this, add a new "Configuration Rule" with a custom filter expression where 
the IP source matches the Fly.io IPv4 or IPv6 address assigned to the machine. This rule turns off the Browser integrity check, and sets the Security Level to "Essentially Off".


# Fly.io Deployment

From `flyio/uptime_kuma`, just run the following, It'll deploy Uptime Kuma to
Fly.io, validate the DNS challenge for SSL certificates, and add `A`/`AAAA`
records. If you use `down` instead of `up`, it'll do the reverse. Don't worry
about running the commands multiple times, they're both idempotent.

```bash
dagger call \
    --fly-api-token=FLY_API_TOKEN \
    --fly-toml=fly.toml \
    --pulumi-access-token=PULUMI_ACCESS_TOKEN \
    --cloudflare-token=CLOUDFLARE_API_TOKEN \
    up
```

> [!note] For simple updates (no DNS certificate) you can just bump the image tag and run `flyctl deploy`.

# AWS Deployment (Depreciated)

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
