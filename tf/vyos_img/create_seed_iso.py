#! python
from jinja2 import Environment, FileSystemLoader
from paramiko import SSHClient
from scp import SCPClient
import requests
import subprocess
import os

vms = [
    {"hostname": "caster", "ip_last_byte": 11},
    {"hostname": "melee", "ip_last_byte": 12},
    {"hostname": "cannon", "ip_last_byte": 13},
    {"hostname": "super", "ip_last_byte": 10},
]

environment = Environment(loader=FileSystemLoader("./"))
template = environment.get_template("user-data.j2")

# Get SSH Keys
r = requests.get("https://github.com/KGB33.keys")
assert r.status_code == 200
ssh_keys = [line.split() for line in r.text.splitlines()]

# Create seed ISOs
for vm in vms:
    # Create user-data
    data = template.render(vm, ssh_keys=ssh_keys)
    with open("user-data", mode="w", encoding="utf-8") as file:
        file.write(data)

    # Create Seed ISO
    subprocess.run(
        f'mkisofs -joliet -rock -volid "cidata" -output {vm["hostname"]}_seed.iso meta-data user-data network-config',
        shell=True,
    )

    # Remove user-data
    os.remove("user-data")

# SCP seed & qcow2 files to respective hosts

for host, seed in [
    ("10.0.9.102", "melee"),
    ("10.0.9.101", "caster"),
    ("10.0.9.103", "cannon"),
    ("10.0.9.102", "super"),
]:
    with SSHClient() as ssh:
        ssh.load_system_host_keys()
        ssh.connect(host, username="root", password=os.getenv("PROXMOX_ROOT"))
        transport = ssh.get_transport()
        assert transport is not None

        with SCPClient(transport) as scp:
            scp.put(f"{seed}_seed.iso", f"/var/lib/vz/template/iso/vyos_{seed}.iso")
            scp.put(f"vyos-1.4.qcow2", "/var/lib/vz/template/iso/vyos-1.4.qcow2")
