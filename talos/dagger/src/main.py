"""
Configures and Bootstraps a talos cluster.
"""

from dataclasses import asdict, dataclass, field
from typing import Annotated
from textwrap import dedent
import asyncio
import time
import base64

import dagger
from dagger import dag, function, object_type, Doc
from jinja2 import BaseLoader, Environment, Template


@dataclass
class Node:
    """
    Describes a Talos Node.
    """

    hostname: str
    ip: str
    control: bool = False
    nameservers: list[str] = field(
        default_factory=lambda: ["10.0.8.53", "1.1.1.1", "1.0.0.1"]
    )


@object_type
class Talos:
    """
    Dagger object to provision and configure a talos cluster.
    """

    raw_template: Annotated[
        dagger.File, Doc("The raw jinia template for Talos patches.")
    ]
    talos_dir: dagger.Directory

    @property
    async def patch_template(self) -> Template:
        """
        Renders the raw jinia template into a Jinja2 Template object.
        """
        return Environment(loader=BaseLoader()).from_string(
            await self.raw_template.contents()
        )

    @function
    def base_img(self) -> dagger.Container:
        """
        Builds a Alpine image with talosctl installed and ready to go.
        """
        return (
            dag.container()
            .from_("alpine:latest")
            .with_exec(["apk", "add", "curl", "openssl", "helm", "kubectl"])
            .with_(talosctl)
            .with_(cilim_cli)
            .with_directory("_out", self.talos_dir)
            .with_workdir("_out")
            .with_env_variable("TALOSCONFIG", "/_out/talosconfig")
        )

    @function
    async def provision(self) -> str:
        """
        Step 1: Provision the nodes.
        """
        async with asyncio.TaskGroup() as tg:
            tasks = [
                tg.create_task(self._provision_nodes(node), name=node.hostname)
                for node in nodes
            ]
        return "\n".join(f"{t.get_name()} done {t.result()}" for t in tasks)

    async def _provision_nodes(self, node: Node) -> str:
        return await (
            self.base_img()
            .pipeline(name=f"Provision {node.hostname}")
            .with_new_file(
                f"{node.hostname}.patch.yaml",
                contents=(await self.patch_template).render(asdict(node)),
            )
            .with_(cache_buster)
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

    @function
    async def bootstrap(self) -> str:
        """
        Step 2: Bootstrap etcd.
        """
        return (
            await self.base_img()
            .pipeline(name="Talos Bootstrap")
            .with_(cache_buster)
            .with_exec(["talosctl", "--nodes", teemo.ip, "bootstrap"])
            .stdout()
        )

    @function
    async def cilium(self) -> str:
        """
        Step 3: Apply Cilium.
        """
        chart = await (
            dag.container()
            .pipeline("Apply Cilium.")
            .from_("alpine")
            .with_exec(["apk", "add", "helm"])
            .with_exec(["helm", "repo", "add", "cilium", "https://helm.cilium.io/"])
            .with_new_file(
                "generateChart.sh",
                permissions=0o750,
                contents=dedent("""
              helm template cilium cilium/cilium \
                --version 1.15.1 --namespace kube-system \
                --set ipam.mode=kubernetes \
                --set kubeProxyReplacement=strict \
                --set k8sServiceHost="10.0.9.25" \
                --set k8sServicePort="6443" \
                --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
                --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
                --set=cgroup.autoMount.enabled=false \
                --set=cgroup.hostRoot=/sys/fs/cgroup \
                --set hubble.listenAddress=":4244" \
                --set hubble.relay.enabled=true \
                --set hubble.ui.enabled=true
            """),
            )
            .with_exec(["sh", "-c", "./generateChart.sh"])
            .stdout()
        )
        return await (
            self.base_img()
            .with_(kubeconfig)
            .with_new_file("/_out/cilium.yaml", contents=chart)
            .with_(cache_buster)
            .with_exec(["kubectl", "apply", "-f", "cilium.yaml"])
            .with_exec(["cilium", "status", "--wait"])
            .stdout()
        )

    @function
    async def argocd(self) -> str:
        """
        Step 4: Start ArgoCD.
        """
        password = (
            await self.base_img()
            .with_(kubeconfig)
            .with_(cache_buster)
            .with_exec(
                [
                    "sh",
                    "-c",
                    "kubectl create namespace argocd; true",
                ]
            )
            .with_exec(
                [
                    "kubectl",
                    "apply",
                    "-n",
                    "argocd",
                    "-f",
                    "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
                ]
            )
            .with_exec(
                [
                    "kubectl",
                    "apply",
                    "-f",
                    "https://raw.githubusercontent.com/KGB33/homelab/main/k8s-apps/meta.yaml",
                ]
            )
            .with_exec(
                [
                    "kubectl",
                    "get",
                    "secrets",
                    "-n",
                    "argocd",
                    "argocd-initial-admin-secret",
                    "-o",
                    "jsonpath='{.data.password}'",
                ]
            )
            .stdout()
        )
        return f"ArgoCD Password:\n\t{base64.b64decode(password).decode('utf-8')}\nFor next steps, go to: https://kgb33.github.io/homelab/k8s/argocd.html"


def kubeconfig(ctr: dagger.Container) -> dagger.Container:
    return ctr.with_exec(["talosctl", "--nodes", teemo.ip, "kubeconfig"])


def talosctl(ctr: dagger.Container) -> dagger.Container:
    INSTALL_SCRIPT = "talosinstall.sh"
    return (
        ctr.with_exec(
            [
                "curl",
                "-sL",
                "https://talos.dev/install",
                "--output",
                INSTALL_SCRIPT,
            ]
        )
        .with_exec(["sh", INSTALL_SCRIPT])
        .with_exec(["rm", INSTALL_SCRIPT])
    )


def cache_buster(ctr: dagger.Container) -> dagger.Container:
    return ctr.with_env_variable("CACHEBUSTER", str(time.time()))


def cilim_cli(ctr: dagger.Container) -> dagger.Container:
    INSTALL_SCRIPT = "cilium_install.sh"
    return (
        ctr.with_new_file(
            INSTALL_SCRIPT,
            permissions=0o750,
            contents=dedent("""
            CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
            CLI_ARCH=amd64
            curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz
            tar x -f cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
            rm cilium-linux-${CLI_ARCH}.tar.gz
        """),
        )
        .with_exec(["sh", "-c", f"./{INSTALL_SCRIPT}"])
        .with_exec(["rm", INSTALL_SCRIPT])
    )


gnar = Node(hostname="gnar", ip="10.0.9.21")
gwen = Node(hostname="gwen", ip="10.0.9.22")
# sion = Node(hostname="sion", ip="10.0.9.23")
# shen =  Node("shen", "10.0.9.24")
teemo = Node(hostname="teemo", ip="10.0.9.25", control=True)
twitch = Node(hostname="twitch", ip="10.0.9.26")
thresh = Node(hostname="thresh", ip="10.0.9.27")
ornn = Node(hostname="ornn", ip="10.0.9.28")
olaf = Node(hostname="olaf", ip="10.0.9.29")
orianna = Node(hostname="orianna", ip="10.0.9.30")

nodes = [gnar, gwen, teemo, twitch, thresh, ornn, olaf, orianna]
