*** Settings ***
Library   SSHLibrary
Library   OperatingSystem
Suite SetupLogin      OKD Host
Suite TeardownClose   All Connections

Resource    vars.robot
Resource    openshift.robot

*** Variables ***
${project_name} temp
${max_pods}     5
${max_cpu}      3
${max_mem}      4Gi
${quota_file}   quota.yaml
${limit_file}   limits.yaml
${quota_name}   compute-resources
${secret_name}  gitlab
${secret_resource_file} secret.yaml

${app_name}     test
${app_image}    openshift/php:7.1
${app_source}   git@gitlab.overcloud.lab:hyagi/test-openshift.git

*** Test Cases ***
Test Create Project
     Create OpenShift Project   ${project_name}
     Create project resource    ${project_name}   ${quota_file}
     Create project resource    ${project_name}   ${limit_file}
     Verify hard limits.cpu quota   ${project_name}   ${quota_name}   ${max_cpu}
     Verify hard limit.memory quota   ${project_name} ${quota_name}   ${max_mem}
     Create SSH Secret (private key)  ${project_name} ${secret_name}  ${secret_resource_file}

Try to scale up pods respecting maximum number of pods
     Create Application ${project_name} ${app_name} ${app_image}  ${app_source} ${secret_name}
     Get pod count
     Stress Application
     Verify new pod count

Try to scale up pods respecting maximum cpu
     Create Application ${project_name} ${app_name} ${app_image}  ${app_source} ${secret_name}
     Get pod count
     Stress Application
     Verify new pod count

*** Keywords ***
Login OKD Host
     Open Connection  ${OKD_HOST_ADDR}
     Login  ${OKD_HOST_USER}  ${OKD_HOST_PASS}

Get pod count
      ${pod_count}   SSHLibrary.Execute Command  oc -n ${project_name} get dc ${app_name} -o go-template --template='{{.status.readyReplicas}}'
      Set Global Variable ${pod_count}
     
Stress Application
     ${output}  SSHLibrary.Execute Command  ulimit -n 65535; ab -n 100000 -c 10000 http://${app_name}-${project_name}.ocp311.lab/

Verify new pod count
     ${max_pod_quota}   SSHLibrary.Execute Command  oc -n ${project_name} get quota ${quota_name} -o go-template --template='{{.spec.hard.pods}}'
     ${new_pod_count}   SSHLibrary.Execute Command  oc -n ${project_name} get dc ${app_name} -o go-template --template='{{.status.readyReplicas}}'
     Should Be True   ${new_pod_count}>${pod_count} and ${new_pod_count}<=${max_pod_quota}
