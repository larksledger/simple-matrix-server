#!/bin/bash

read -p "Enter the name of the new user: " USERNAME
read -p "Is new user admin (y|n)?(n)" ISADMIN

# Set default to 'n' if the input is empty or just whitespace
ISADMIN=${ISADMIN:-n}

# Convert input to lowercase for case-insensitive checking
ISADMIN_LOWER=$(echo "$ISADMIN" | tr '[:upper:]' '[:lower:]')

if [[ "$ISADMIN_LOWER" == "y" || "$ISADMIN_LOWER" == "yes" ]]; then
	docker exec -it simple-matrix-server-monolith-1 /usr/bin/create-account -config /etc/dendrite/dendrite.yaml -username $USERNAME -admin
else
	docker exec -it simple-matrix-server-monolith-1 /usr/bin/create-account -config /etc/dendrite/dendrite.yaml -username $USERNAME
fi
echo "Done."