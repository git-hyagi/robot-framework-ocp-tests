*** Settings ***
Library         Process
Library         OperatingSystem
Library         String
Resource        vars.robot
Resource        keywords.resource
Suite Setup     Configure Pulp

*** Test Cases ***

Ensure 1 replica of api pod
    Run Process         ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"api": {"replicas": 1}}}'     stderr=STDOUT  shell=yes
    ${replicas}         Run Process     ${oc} get deployment/${api_deployment_name} -ojsonpath\='{.status.readyReplicas}'       stderr=STDOUT  shell=yes
    Should Be Equal     ${replicas.stdout}      1

Ensure 1 replica of content pod
    Run Process         ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"content": {"replicas": 1}}}'     stderr=STDOUT  shell=yes
    ${replicas}         Run Process     ${oc} get deployment/${content_deployment_name} -ojsonpath\='{.status.readyReplicas}'       stderr=STDOUT  shell=yes
    Should Be Equal     ${replicas.stdout}      1

Ensure 1 replica of worker pod
    Run Process         ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"worker": {"replicas": 1}}}'     stderr=STDOUT  shell=yes
    ${replicas}         Run Process     ${oc} get deployment/${worker_deployment_name} -ojsonpath\='{.status.readyReplicas}'       stderr=STDOUT  shell=yes
    Should Be Equal     ${replicas.stdout}      1

Ensure rollout strategy configuration for api deployment
    Run Process         ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"api": {"strategy": {"type": "RollingUpdate", "rollingUpdate": { "maxUnavailable": "25%"}}}}}'        stderr=STDOUT  shell=yes
    ${strategy}         Run Process     ${oc} get deployment/${api_deployment_name} -ojsonpath\='{.spec.strategy.rollingUpdate.maxUnavailable}'     stderr=STDOUT  shell=yes
    Should Be Equal     ${strategy.stdout}      25%

Ensure rollout strategy configuration for content deployment
    Run Process         ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"content": {"strategy": {"type": "RollingUpdate", "rollingUpdate": { "maxUnavailable": "25%"}}}}}'        stderr=STDOUT  shell=yes
    ${strategy}         Run Process     ${oc} get deployment/${content_deployment_name} -ojsonpath\='{.spec.strategy.rollingUpdate.maxUnavailable}'     stderr=STDOUT  shell=yes
    Should Be Equal     ${strategy.stdout}      25%

Ensure rollout strategy configuration for worker deployment
    Run Process         ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"worker": {"strategy": {"type": "RollingUpdate", "rollingUpdate": { "maxUnavailable": "25%"}}}}}'        stderr=STDOUT  shell=yes
    ${strategy}         Run Process     ${oc} get deployment/${worker_deployment_name} -ojsonpath\='{.spec.strategy.rollingUpdate.maxUnavailable}'     stderr=STDOUT  shell=yes
    Should Be Equal     ${strategy.stdout}      25%

Ensure Pulp is accessible from outside of OCP cluster
    ${default_domain}       Run Process         /usr/bin/oc -n openshift-ingress-operator get ingresscontrollers default -ojsonpath\='{.status.domain}'        stderr=STDOUT  shell=yes
    ${route_host}           Catenate        SEPARATOR=      pulp.   ${default_domain.stdout}
    Run Process             ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"ingress_type": "route", "route_host": "${route_host}" }}'        stderr=STDOUT  shell=yes
    Run Process             ${oc} wait --for condition\=Pulp-Operator-Finished-Execution pulp/${pulp_resource_name} --timeout\=900s         stderr=STDOUT  shell=yes

    ${pulp_status}          Run Process             ${pulp_cli} status         stderr=STDOUT  shell=yes
    Log                     ${pulp_status.stdout}
    ${pulp_status_json}     Evaluate                json.loads("""${pulp_status.stdout}""")    modules=json
    Log                     ${pulp_status_json}
    Should Be True          len(${pulp_status_json["online_workers"]}) >= ${1}
    Should Be True          len(${pulp_status_json["online_api_apps"]}) >= ${1}
    Should Be True          len(${pulp_status_json["online_content_apps"]}) >= ${1}


#Start file upload
#Modify image_version to simulate upgrade
#Ensure pulpcore pods won't get killed while receiving the file
#Verify file integrity (compare hash)
#
#
#Start file download
#Modify image_version to simulate upgrade
#Ensure pulpcore pods won't get killed while sending the file
#Verify file integrity (compare hash)