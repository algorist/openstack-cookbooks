name "openldap"
run_list [ "recipe[apt]", "recipe[nova::openldap]" ]

