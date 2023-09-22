*** Variables ***
${project_name}         pulp
${oc}                   /usr/bin/oc -n ${project_name}
${pulp_resource_name}   test-pulp-ha
${get_pulp}             ${oc} get pulp ${pulp_resource_name}


## replica tests
${api_replicas}         6
${content_replicas}     6
${worker_replicas}      6

## affinity rules tests
#${expected_api_affinity}    catenate
#...     {
#...         "podAntiAffinity":{
#...             "preferredDuringSchedulingIgnoredDuringExecution":[{
#...                 "podAffinityTerm": {
#...                     "labelSelector": {
#...                         "matchExpressions": [
#...                             {"key":"app.kubernetes.io/component","operator":"In","values":["api"]}
#...                         ]
#...                     },
#...                     "topologyKey":"topology.kubernetes.io/zone"
#...                 },
#...             "weight":100
#...     }]}}
