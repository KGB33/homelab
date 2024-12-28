 #!/usr/bin/env fish
set -euo pipefail

set username $USER

if not test (string tolower $username) = "kgb33"
    echo "Run this script as 'kgb33' - got $username."
    exit 1
end

set clone_dir "/mnt/home/kgb33/homelab"

mkdir $clone_dir
cd $clone_dir

git init
git remote 
git sparse-checkout init
git sparse-checkout set "nixos"
git pull origin main
