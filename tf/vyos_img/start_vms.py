#! python
import time
import os
from dataclasses import dataclass
from paramiko import SSHClient

QCOW2_NAME = "vyos-1.4.qcow2"


@dataclass
class VMData:
    vmID: int
    host: str
    name: str


vm_data = [
    VMData(vmID=801, host="10.0.9.101", name="caster"),
    VMData(vmID=802, host="10.0.9.102", name="melee"),
    VMData(vmID=803, host="10.0.9.103", name="cannon"),
]

with SSHClient() as client:
    client.load_system_host_keys()
    for vm in vm_data:
        client.connect(
            hostname=vm.host, username="root", password=os.getenv("PROXMOX_ROOT")
        )
        client.exec_command(
            f"qm create {vm.vmID} --name {vm.name}.k8s.kgb33.dev --memory 1024 --net0 virtio,bridge=vmbr0"
        )
        time.sleep(10)
        client.exec_command(
            f"qm importdisk {vm.vmID} /var/lib/vz/template/iso/vyos-1.4.qcow2 local"
        )
        time.sleep(10)
        client.exec_command(
            f"qm set {vm.vmID} --virtio0 local:{vm.vmID}/vm-{vm.vmID}-disk-0.raw"
        )
        time.sleep(10)
        client.exec_command(f"qm set {vm.vmID} --boot order=virtio0")
        time.sleep(10)
        client.exec_command(
            f"qm set {vm.vmID} --ide2 media=cdrom,file=local:iso/vyos_seed.iso"
        )
        time.sleep(10)
        client.exec_command(f"qm set {vm.vmID} --net1 virtio,bridge=vmbr1")
#        client.exec_command(f"qm start {vm.vmID}")
#        client.exec_command(f"qm stop {vm.vmID}")
#        client.exec_command(f"qm destroy {vm.vmID}")
