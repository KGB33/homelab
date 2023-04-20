#! /bin/python
import subprocess

nodes: dict[str, str] = {
    "teemo.kgb33.dev": "10.0.0.116",
}

for hostname, ip in nodes.items():
    subprocess.run(
        [
            "talosctl",
            "apply-config",
            "--insecure",
            "--nodes",
            ip,
            "--config-patch",
            f"@patches/{hostname}.patch",
            "--config-patch",
            "@patches/all_nodes.patch",
            "--config-patch",
            "@patches/control_planes.patch",
            "--file",
            "./controlplane.yaml",
        ],
    )
