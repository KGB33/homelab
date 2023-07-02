#! python
import os
import time
from dataclasses import dataclass
from paramiko import SSHClient


@dataclass
class VMData:
    vmID: int
    host: str
    name: str


vm_data = [
    VMData(vmID=801, host="10.0.9.101", name="caster"),
    VMData(vmID=802, host="10.0.9.102", name="melee"),
    VMData(vmID=803, host="10.0.9.103", name="cannon"),
    VMData(vmID=800, host="10.0.9.102", name="super"),
]

with SSHClient() as client:
    client.load_system_host_keys()
    for vm in vm_data:
        client.connect(
            hostname=vm.host, username="root", password=os.getenv("PROXMOX_ROOT")
        )
        client.exec_command(f"qm stop {vm.vmID}")
        time.sleep(3)
        client.exec_command(f"qm destroy {vm.vmID}")
        time.sleep(3)
