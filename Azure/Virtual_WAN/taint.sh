#!/bin/bash
module=$1
echo "tainting all resources in module ${module}"
read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    terraform state list | grep module.${module} | xargs -n1 terraform taint
else
    echo "canceling"
fi
