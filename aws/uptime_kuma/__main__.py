from pulumi import Config, Output, export
import pulumi_aws as aws
import pulumi_awsx as awsx

NAME_PREFIX = "uptime-kuma"

config = Config()
container_port = config.get_int("containerPort", 3001)
cpu = config.get_int("cpu", 512)
memory = config.get_int("memory", 128)

# An ECS cluster to deploy into
cluster = aws.ecs.Cluster(f"{NAME_PREFIX}-cluster")

# An ALB to serve the container endpoint to the internet
loadbalancer = awsx.lb.ApplicationLoadBalancer(
    f"{NAME_PREFIX}-loadbalancer", listener=awsx.lb.ListenerArgs(port=3001)
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
