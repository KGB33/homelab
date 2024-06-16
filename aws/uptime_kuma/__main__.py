from pulumi import Config, Output, export
import pulumi_aws as aws
import pulumi_awsx as awsx
import pulumi_cloudflare as cf

NAME_PREFIX = "uptime-kuma"


def validate_aws_cert() -> str:
    """
    Creates an AWS certifcate for the given domain,
    Validates it via the DNS challage on Cloudflare,
    Returns the Certificate's ARN
    """
    DOMAIN = "uptime.kgb33.dev"

    # Create cert in AWS
    ssl_cert = aws.acm.Certificate(
        f"{NAME_PREFIX}-cert", domain_name=DOMAIN, validation_method="DNS"
    )

    # Create CNAME in Cloudflare
    def create_records(
        dvo: list[aws.acm.CertificateDomainValidationOptionArgs],
    ) -> cf.Record:
        dvo = dvo[0]
        return cf.Record(
            f"{DOMAIN}-validator",
            zone_id="33f1d2b5c5cc2302c6487142d00cfc8f",
            name=dvo.resource_record_name,
            type=dvo.resource_record_type,
            value=dvo.resource_record_value,
        )

    ssl_cert.domain_validation_options.apply(create_records)
    return ssl_cert.arn


config = Config()
container_port = config.get_int("containerPort", 3001)
cpu = config.get_int("cpu", 512)
memory = config.get_int("memory", 128)

# An ECS cluster to deploy into
cluster = aws.ecs.Cluster(f"{NAME_PREFIX}-cluster")

cert_arn = validate_aws_cert()
# An ALB to serve the container endpoint to the internet
loadbalancer = awsx.lb.ApplicationLoadBalancer(
    f"{NAME_PREFIX}-loadbalancer",
    listener=awsx.lb.ListenerArgs(protocol="HTTPS", certificate_arn=cert_arn),
    default_target_group=awsx.lb.TargetGroupArgs(
        port=container_port,
        protocol="HTTP",
        health_check=aws.lb.TargetGroupHealthCheckArgs(enabled=True, path="/dashboard"),
    ),
)

# Deploy an ECS Service on Fargate to host the application container
service = awsx.ecs.FargateService(
    f"{NAME_PREFIX}-service",
    cluster=cluster.arn,
    assign_public_ip=True,
    task_definition_args=awsx.ecs.FargateServiceTaskDefinitionArgs(
        container=awsx.ecs.TaskDefinitionContainerDefinitionArgs(
            name=f"{NAME_PREFIX}-task",
            image="louislam/uptime-kuma",
            cpu=cpu,
            memory=memory,
            essential=True,
            port_mappings=[
                awsx.ecs.TaskDefinitionPortMappingArgs(
                    container_port=container_port,
                    host_port=container_port,
                    target_group=loadbalancer.default_target_group,
                )
            ],
        ),
    ),
)

# The URL at which the container's HTTP endpoint will be available
export("url", Output.concat("http://", loadbalancer.load_balancer.dns_name))
