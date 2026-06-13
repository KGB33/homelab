## Fleet Summary

# Fleet Summary

## Topology

- **0** environments, **3** hosts, **3** users
- Scope chain: flake → flake-system → user → host
- Trace entries: 144

## Environments

| Environment | Hosts | Host Count | Users |
| ------------- | ------- | ------------ | ------- |

## Aspects by Host

| Host | Aspect Count | Aspects |
| ------ | -------------- | --------- |
| ophiuchus | 3 | insecure-predicate/os, ophiuchus, unfree-predicate/os |
| targe | 3 | insecure-predicate/os, targe, unfree-predicate/os |
| tower | 3 | insecure-predicate/os, tower, unfree-predicate/os |



## Policies

| Policy | Fires at |
| -------- | ---------- |
| flake-to-systems | flake |
| apps-to-flake | flake-system |
| checks-to-flake | flake-system |
| devShells-to-flake | flake-system |
| legacyPackages-to-flake | flake-system |
| packages-to-flake | flake-system |
| system-to-os-outputs | flake-system |
| host-to-users | host |
| os-to-host | host |
| kgb33/to-hosts | user |
| user-to-host | user |
