*** Settings ***
Library     Process
Resource    vars.robot
Test Setup       Set expected Api Affinity configuration

*** Test Cases ***

Ensure anti-affinity rules for API pods
    ${result}    Run Process     ${get_pulp} -ojsonpath\='{.spec.api.affinity}'   stderr=STDOUT  shell=yes
    Log     ${result.stdout}
    ${result_json}  Evaluate    json.loads("""${result.stdout}""")    modules=json
    Log     ${result_json}
    
    
    ${json_api_affinity}        Evaluate       json.loads("""${expected_api_affinity}""")       modules=json
    Log     ${json_api_affinity}
    Should Be Equal     ${result_json}  ${json_api_affinity}


*** Keywords ***

## affinity rules tests
Set expected Api Affinity configuration
    ${expected_api_affinity}    catenate
    ...     {
    ...         "podAntiAffinity":{
    ...             "preferredDuringSchedulingIgnoredDuringExecution":[{
    ...                 "podAffinityTerm": {
    ...                     "labelSelector": {
    ...                         "matchExpressions": [
    ...                             {"key":"app.kubernetes.io/component","operator":"In","values":["api"]}
    ...                         ]
    ...                     },
    ...                     "topologyKey":"topology.kubernetes.io/zone"
    ...                 },
    ...             "weight":100
    ...     }]}}