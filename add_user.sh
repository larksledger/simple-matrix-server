#!/bin/bash

PASSWORD=""
echo "Note: First user will have admin privileges."
read -p "Enter the name of the user: " USERNAME
function prompt_and_confirm_password {
	local password=""
    local password_confirm=""
	while true; do
		read -s -r -p "Enter the password of the admin user: " password
		echo ""
		read -s -r -p "Confirm password: " password_confirm
		echo ""
		if [ "$password" = "$password_confirm" ]; then
			PASSWORD="$password"
			password=""
			password_confirm=""
			return 0
		else
			echo ""
            echo "❌ Passwords DO NOT match. Please try again."
		fi
	done
	}
	
if prompt_and_confirm_password; then
	# Make sure the service is not running
	docker compose down
	
	# Add the admin user
	docker compose run \
	  --rm continuwuity \
	  conduwuit --execute "users create-user $USERNAME $PASSWORD"
  	PASSWORD=""
	echo "Done."
fi
