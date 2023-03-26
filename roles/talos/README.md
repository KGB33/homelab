Role Name
=========

Creates a k8s cluster given a collection of unintalized talos hosts.

Role Variables
--------------

Each host needs to have a variable `k8s_role` with the value `control` or `worker`.
