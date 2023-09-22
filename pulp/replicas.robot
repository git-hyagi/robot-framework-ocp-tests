*** Settings ***
Library     Process
Resource    vars.robot

*** Test Cases ***

Ensure Pulpcore API replicas
    ${pulp}    Run Process     ${get_pulp} -ojsonpath\='{.spec.api.replicas}'   stderr=STDOUT  shell=yes
    ${deployment}   Run Process    ${oc} get deployment/${pulp_resource_name}-api -ojsonpath\='{.status.readyReplicas}'     stderr=STDOUT   shell=yes
    Should Be Equal     ${pulp.stdout}    ${api_replicas}
    Should Be Equal     ${deployment.stdout}    ${api_replicas}


Ensure Pulpcore Worker replicas
    ${pulp}    Run Process     ${get_pulp} -ojsonpath\='{.spec.worker.replicas}'   stderr=STDOUT  shell=yes
    ${deployment}   Run Process    ${oc} get deployment/${pulp_resource_name}-worker -ojsonpath\='{.status.readyReplicas}'  stderr=STDOUT   shell=yes
    Should Be Equal     ${pulp.stdout}    ${worker_replicas}
    Should Be Equal     ${deployment.stdout}    ${worker_replicas}

Ensure Pulpcore Content replicas
    ${pulp}    Run Process     ${get_pulp} -ojsonpath\='{.spec.content.replicas}'   stderr=STDOUT  shell=yes
    ${deployment}   Run Process    ${oc} get deployment/${pulp_resource_name}-content -ojsonpath\='{.status.readyReplicas}'     stderr=STDOUT   shell=yes
    Should Be Equal     ${pulp.stdout}    ${content_replicas}
    Should Be Equal     ${deployment.stdout}    ${content_replicas}
