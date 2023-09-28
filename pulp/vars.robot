*** Variables ***
${project_name}         pulp
${oc}                   /usr/bin/oc -n ${project_name}
${pulp_resource_name}   test-pulp-ha
${get_pulp}             ${oc} get pulp ${pulp_resource_name}
${pulp_cli}             ~/.local/bin/pulp
${pulp_user}            admin
${pulp_pwd}             password
${TEST_FILE_PATH}       ~/Downloads/go1.19.linux-amd64.tar.gz
${TEST_FILE_NAME}       go.tar.gz
${TEST_FILE_SHA}        464b6b66591f6cf055bc5df90a9750bf5fbc9d038722bb84a9d56a2bea974be6
${TEST_FILE_REPO}       foo
${TEST_FILE_DISTRIBUTION}       bar
${TEST_REPO_SYNC}       http://fedora.c3sl.ufpr.br/linux/updates/38/Everything/x86_64/

## labels
${api_label}            app.kubernetes.io/component=api
${content_label}        app.kubernetes.io/component=content
${worker_label}         app.kubernetes.io/component=worker

## replica tests
${api_replicas}         6
${content_replicas}     6
${worker_replicas}      6

## PDB
${api_pdb_name}             ${pulp_resource_name}-api
${content_pdb_name}         ${pulp_resource_name}-content
${worker_pdb_name}          ${pulp_resource_name}-worker
${api_min_available}        ${3}
${content_max_unavailable}  50%
${worker_min_available}     ${2}

## deployments
${api_deployment_name}             ${api_pdb_name}
${content_deployment_name}         ${content_pdb_name}
${worker_deployment_name}          ${worker_pdb_name}


## nodeSelector
${worker_node_selector}     is_spot_instance=true