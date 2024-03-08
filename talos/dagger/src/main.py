from dataclasses import asdict, field
from typing import Annotated, Coroutine
import asyncio
import time

import dagger
from dagger import dag, function, object_type, Doc
from jinja2 import BaseLoader, Environment, Template


@object_type
class Node:
    hostname: str
    ip: str
    control: bool = False
    nameservers: list[str] = field(
        default_factory=lambda: ["10.0.8.53", "1.1.1.1", "1.0.0.1"]
    )


@object_type
class Talos:
    raw_template_file: Annotated[
        dagger.File, Doc("The raw jinia template for Talos patches.")
    ]
    talos_dir: dagger.Directory

    @property
    async def patch_template(self) -> Template:
        return Environment(loader=BaseLoader()).from_string(
            await self.raw_template_file.contents()
        )

    @function
    def base_img(self) -> dagger.Container:
        return (
            dag.container()
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
            .with_directory("_out", self.talos_dir)
            .with_workdir("_out")
            .with_env_variable("TALOSCONFIG", "/_out/talosconfig")
        )

    @function
    async def provision_nodes(self) -> str:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(self._provision_nodes(node), name=node.hostname) for node in nodes]
        return "\n".join(f"{t.get_name()} done {t.result()}" for t in tasks)

    async def _provision_nodes(self, node: Node) -> str:
        return await (
            self.base_img()
            .with_new_file(
                f"{node.hostname}.patch.yaml",
                contents=(await self.patch_template).render(asdict(node)),
            )
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
            .stdout()
        )


gnar = Node(hostname="gnar", ip="10.0.9.21", control=True)
gwen = Node(hostname="gwen", ip="10.0.9.22")
sion = Node(hostname="sion", ip="10.0.9.23", control=True)
# shen = Node("shen", "10.0.9.24")
teemo = Node(hostname="teemo", ip="10.0.9.25", control=True)
twitch = Node(hostname="twitch", ip="10.0.9.26")

nodes = [gnar, gwen, sion, twitch, teemo]
