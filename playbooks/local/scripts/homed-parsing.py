#!/bin/python3

import subprocess
import json


if __name__ == "__main__":
    cmd = subprocess.run(["homectl", "inspect", "-EE"], capture_output=True, check=True)
    data = json.loads(cmd.stdout)
    del data["privileged"]
    with open("vars/kgb33.identity", "w+") as file:
        json.dump(data, file, indent=4)
