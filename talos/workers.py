#! /bin/python
import subprocess

nodes: dict[str, str] = {
    "twitch.kgb33.dev": "10.0.0.117",
    "gnar.kgb33.dev": "10.0.0.112",
    "gwen.kgb33.dev": "10.0.0.113",

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
            f"@patches/all_nodes.patch",
            "--file",
            "./worker.yaml",
        ],
    )
