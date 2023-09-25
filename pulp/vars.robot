*** Variables ***
${project_name}         pulp
${oc}                   /usr/bin/oc -n ${project_name}
${pulp_resource_name}   test-pulp-ha
${get_pulp}             ${oc} get pulp ${pulp_resource_name}


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


## nodeSelector
${worker_node_selector}     is_spot_instance=true