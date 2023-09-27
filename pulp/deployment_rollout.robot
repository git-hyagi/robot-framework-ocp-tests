*** Settings ***
Library         Process
Library         OperatingSystem
Library         String
Resource        vars.robot
Resource        keywords.resource
Suite Setup     Configure Pulp

*** Test Cases ***

Update API replicas
    Run Process             ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"api": {"replicas": 1}}}'     stderr=STDOUT  shell=yes
    ${api_replicas}         Run Process     ${oc} get deployment/${api_deployment_name} -ojsonpath\='{.status.readyReplicas}'       stderr=STDOUT  shell=yes
    Set Global Variable     ${api_replicas}

Update content replicas
    Run Process                 ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"content": {"replicas": 1}}}'     stderr=STDOUT  shell=yes
    ${content_replicas}         Run Process     ${oc} get deployment/${content_deployment_name} -ojsonpath\='{.status.readyReplicas}'       stderr=STDOUT  shell=yes
    Set Global Variable         ${content_replicas}

Update worker replicas
    Run Process                ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"worker": {"replicas": 1}}}'     stderr=STDOUT  shell=yes
    ${worker_replicas}         Run Process     ${oc} get deployment/${worker_deployment_name} -ojsonpath\='{.status.readyReplicas}'       stderr=STDOUT  shell=yes
    Set Global Variable        ${worker_replicas}

Update rollout strategy configuration for api deployment
    Run Process                ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"api": {"strategy": {"type": "RollingUpdate", "rollingUpdate": { "maxUnavailable": "25%"}}}}}'        stderr=STDOUT  shell=yes
    ${api_strategy}            Run Process     ${oc} get deployment/${api_deployment_name} -ojsonpath\='{.spec.strategy.rollingUpdate.maxUnavailable}'     stderr=STDOUT  shell=yes
    Set Global Variable        ${api_strategy}

Update rollout strategy configuration for content deployment
    Run Process                ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"content": {"strategy": {"type": "RollingUpdate", "rollingUpdate": { "maxUnavailable": "25%"}}}}}'        stderr=STDOUT  shell=yes
    ${content_strategy}        Run Process     ${oc} get deployment/${content_deployment_name} -ojsonpath\='{.spec.strategy.rollingUpdate.maxUnavailable}'     stderr=STDOUT  shell=yes
    Set Global Variable        ${content_strategy}

Update rollout strategy configuration for worker deployment
    Run Process                ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"worker": {"strategy": {"type": "RollingUpdate", "rollingUpdate": { "maxUnavailable": "25%"}}}}}'        stderr=STDOUT  shell=yes
    ${worker_strategy}         Run Process     ${oc} get deployment/${worker_deployment_name} -ojsonpath\='{.spec.strategy.rollingUpdate.maxUnavailable}'     stderr=STDOUT  shell=yes
    Set Global Variable        ${worker_strategy}

Wait operator sync replicas/rollout tasks
    Wait Pulp sync tasks

Validate configurations
    Should Be Equal     ${api_replicas.stdout}      1
    Should Be Equal     ${content_replicas.stdout}      1
    Should Be Equal     ${worker_replicas.stdout}      1
    Should Be Equal     ${api_strategy.stdout}      25%
    Should Be Equal     ${content_strategy.stdout}      25%
    Should Be Equal     ${worker_strategy.stdout}      25%

Ensure Pulp is accessible from outside of OCP cluster
    Run Process             ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"ingress_type": "route", "route_host": "${route_host}" }}'        stderr=STDOUT  shell=yes
    Run Process             ${oc} wait --for condition\=Pulp-Operator-Finished-Execution pulp/${pulp_resource_name} --timeout\=900s         stderr=STDOUT  shell=yes
    Set Global Variable        ${route_host}

    ${pulp_status}          Run Process             ${pulp_cli} status         stderr=STDOUT  shell=yes
    Log                     ${pulp_status.stdout}
    ${pulp_status_json}     Evaluate                json.loads("""${pulp_status.stdout}""")    modules=json
    Log                     ${pulp_status_json}
    Should Be True          len(${pulp_status_json["online_workers"]}) >= ${1}
    Should Be True          len(${pulp_status_json["online_api_apps"]}) >= ${1}
    Should Be True          len(${pulp_status_json["online_content_apps"]}) >= ${1}

