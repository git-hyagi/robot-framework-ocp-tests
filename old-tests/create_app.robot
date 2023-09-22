*** Settings ***
Library		SSHLibrary
Library		OperatingSystem
Suite SetupLogin    OKD Host
Suite Teardown	    Close All Connections

Resource	vars.robot
Resource	openshift.robot

*** Variables ***
${project_name}	    temp
${max_pods}	    5
${max_cpu}	    3
${max_mem}	    4Gi
${quota_file}	    quota.yaml
${limit_file}	    limits.yaml
${quota_name}	    compute-resources
${secret_name}	    gitlab
${secret_resource_file}	    secret.yaml

${app_name}	test
${app_image}	openshift/php:7.1
${app_source}	git@gitlab.overcloud.lab:hyagi/test-openshift.git

*** Test Cases ***
Test Create Project
Create OpenShift Project    ${project_name}
Create project resource	    ${project_name}	${quota_file}
Create project resource	    ${project_name}	${limit_file}
Verify hard limits.cpu quota	${project_name}	    ${quota_name}   ${max_cpu}
Verify hard limit.memory quota  ${project_name}	    ${quota_name}   ${max_mem}
Create SSH Secret (private key)	${project_name}	    ${secret_name}  ${secret_resource_file}

Test Create Application
Create Application$	{project_name}	    ${app_name}	    ${app_image}    ${app_source}   ${secret_name}

*** Keywords ***
Login OKD Host
	Open Connection	    ${OKD_HOST_ADDR}
	Login	    ${OKD_HOST_USER}	${OKD_HOST_PASS}
