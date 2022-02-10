# Account creation
Unfortunately `homectl` does not seem to be script-able at the moment.
As a result, before running this playbook create a user account. 

```
homectl create --idet=./vars/kgb33.identity
```


# Local Testing

Run 
```console
ansible-playbook local.yml -i inventory.yml
```

# Pull from remote git
Run 
```console
ansible-pull -U https://git.kgb33.dev/kgb33/ansible.git
```

# Generate Package Lists
Arch Repos
```console
paru -Qqe | rg -v '$(pacman -Qqm)'
```

AUR
```console
paru -Qqm
```
