#!/bin/bash
#echo "This will destroy your deployment, no going back from here - Press enter to continue"
# apply
#read -r -p "Are you sure? [y/N] " response
#if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
#then
    terraform destroy --auto-approve
#else
#    echo "canceling"
#fi
