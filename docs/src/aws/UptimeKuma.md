# Uptime Kuma

An off-site uptime monitoring solution hosted on AWS ECS.

> [uptime.kgb33.dev](https://uptime.kgb33.dev/)

# ClickOps Steps

Starting at the [ECS dashboard](https://console.aws.amazon.com/ecs/v2/clusters).
  - Click "Create Cluster"
  - Name the new cluster whatever - I choose `uptime-kuma`.
  - Change Infrastructure to "Amazon EC2 Instances" then:
    - For "Auto Scaling Group" select "Create new ASG"
    - Use the "On-demand" Provisioning model
    - Keep the default "Container Instance Amazon Machine Image" (Amazon Linux 2 - kernal 5.10)
    - Create new EC2 Instance role
    - Lower the desired capactity - Min: 0, Max: 3
    - Skip the SSH key pair.
  - Keep the defaults for Network Settings, Montoring, and Tags.

Next, from the newly-created cluster overview, create a service:
  - Keep the defaults, then Create a new task

Task definitions:
  - Family: `uptime-kuma`
  - Infrastructure Requirements:
    - Uncheck "AWS Fargate"
    - Check "Amazon EC2 Instances"
  - Container Info:
    - Name: `uptime-kuma`
    - Image URI: `louislam/uptime-kuma`
    - Change the container port to `3001`

Create the task then go back to the service creation, select the newly create
task (you might need to refresh), and click create.
