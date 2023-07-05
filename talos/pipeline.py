from dataclasses import asdict
import dagger
import asyncio
import time

from jinja2 import Environment, FileSystemLoader, Template

from data import nodes, TalosVM


async def provision_nodes(img: dagger.Container, template: Template, node: TalosVM):
    # https://docs.dagger.io/7442989/cookbook#invalidate-cache
    await (
        img.with_new_file(f"{node.hostname}.patch.yaml", contents=template.render(asdict(node)))
        .with_env_variable("CACHEBUSTER", str(time.time()))
        .with_exec(
            [
                "talosctl",
                "apply-config",
                "--insecure",
                "--nodes",
                node.ip,
                "--config-patch",
                f"@{node.hostname}.patch.yaml",
                "--file",
                f"{'./controlplane.yaml' if node.control else './worker.yaml'}",
            ]
        )
    )


async def main():
    # Load Jinja2 Templage
    template = Environment(loader=FileSystemLoader("templates")).get_template(
        "talos.yaml.j2"
    )

    # Create Dagger Config & Connection
    cfg = dagger.Config()
    async with dagger.Connection(cfg) as client:
        # Create base image w/ talosctl installed
        base_img = (
            await client.container()
            .from_("alpine:latest")
            .with_exec(["apk", "add", "curl", "openssl"])
            .with_exec(
                [
                    "curl",
                    "-sL",
                    "https://talos.dev/install",
                    "--output",
                    "talosinstall.sh",
                ]
            )
            .with_exec(["sh", "talosinstall.sh"])
            .with_directory(
                ".",
                client.host().directory(".", include=["_out/"]),
            )
            .with_workdir("_out")
        )

        # Create TaskGroups to provision each node
        async with asyncio.TaskGroup() as tg:
            for node in nodes:
                tg.create_task(provision_nodes(base_img, template, node))


if __name__ == "__main__":
    asyncio.run(main())
