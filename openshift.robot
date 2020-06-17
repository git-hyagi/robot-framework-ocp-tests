*** Settings ***
Library		OperatingSystem

*** Keywords ***
Create OpenShift Project
    [Documentation]	Test project creation
    ...			should create a new project with name ${project} if ok
    [Arguments]		${project}
    [Tags]		project
    
    ${exists}	Execute Command	    oc project ${project}	return_stdout=False	return_rc=True
    Run Keyword If	${exists}>0	Execute Command	    oc new-project ${project}	    return_stdout=False     return_rc=True

Create project resource
    [Documentation]	Create a project resource based on a yaml file
    ...			should create a new resource
    [Arguments]		${project}	${file_name}
    [Tags]		project	    resources	    admin

    # Must be logged as an admin user
    Login with another user	system:admin
    
    # Load resource file
    ${resource_file}	OperatingSystem.Get File    ${file_name}
    ${exists}               Execute Command         oc project ${project}   return_stdout=False     return_rc=True
    Run Keyword If          ${exists}==0     Execute Command         echo \\"${resource_file}\\" | oc -n ${project} create -f -

Login with another user
    [Arguments]	    ${user}
    ${output}	    Execute Commandoc login -u ${user}
    Should Contain	${output}   Logged into

Verify hard limits.cpu quota
    [Arguments]	    ${project}	     ${quota_name}	${cpu}
    ${output}       Execute Command         oc -n ${project} get quota ${quota_name} -o go-template --template=\'{{index .spec.hard \"limits.cpu\" }}\'
    Should Be True  ${output} == ${cpu}

Verify hard limit.memory quota
    [Arguments]	    ${project}	    ${quota_name}	${memory}
    ${output}       Execute Command         oc -n ${project} get quota ${quota_name} -o go-template --template=\'{{index .spec.hard \"limits.memory\" }}\'
    Should Be Equal As Strings      ${output}       ${memory}

Verify hard pods count quota
    [Arguments]	    ${project}	    ${quota_name}	${pods}
    ${output}       Execute Command         oc -n ${project} get quota ${quota_name} -o go-template --template=\'{{index .spec.hard \"pods\" }}\'
    Should Be Equal As Strings      ${output}       ${pods}

Create SSH Secret (private key)
    [Arguments]	    ${project}	    ${secret_name}	${secret_resource_file}
    ${exists}	    Execute Command	oc -n ${project} get secret ${secret_name}  return_stdout=False     return_rc=True
    Run Keyword If	${exists}>0	Create project resource	    ${project}	    ${secret_resource_file}

Create Application
    [Documentation]	Test app creation
    [Tags]		project	    app	    pods	service	    route
    [Arguments]		${project}	${app_name}	${app_image}	    ${app_source}	${source_secret}

    ${exists}	Execute Command	    oc -n ${project} get dc ${app_name}	    return_stdout=False     return_rc=True
    Run Keyword If  ${exists}>0	    Execute Command	oc -n ${project} new-app ${app_image}~${app_source} --name ${app_name} --source-secret=${source_secret} 2>&1

    ${output}	Execute Commandoc -n ${project} get dc ${app_name}
    Should contain  ${output}	${app_name}
    ${output}	Execute Command	    oc -n ${project} get service ${app_name}
    Should contain	${output}   ${app_name}
    ${output}	    Execute Command	oc -n ${project} get bc ${app_name}
    Should contain	${output}	${app_name}

    Expose Service	${project}  ${app_name}

Expose Service
    [Documentation]	Create route
    [Arguments]		${project}	${app_name}
    ${exists}	    Execute Command	oc -n ${project} get route ${app_name}	    return_stdout=False     return_rc=True
    Run Keyword If	${exists}>0	Execute Command	    oc -n ${project} expose svc ${app_name}

Verify that build pod is working
    [Documentation]	Wait until build pod finishes work
    [Tags]		pods
    [Arguments]		${project}	    ${pod}
    Wait Until Keyword Succeeds	    5 min	5 sec	    Build pod is not ready	${project}	${pod}

Build pod is not ready
    [Arguments]	    ${project}	    ${pod}
    ${output}	    Execute Command	oc -n ${project} get pod ${pod} -o go-template --template=\'{{.status.phase}}\'
    Should Be Equal As Strings	    ${output}	    Succeeded

Verify build status
    [Arguments]		${project}	${build_name}
    ${output}		Execute Command	    oc -n ${project} get builds ${build_name} -o go-template --template=\'{{.status.phase}}\'
    Should Be Equal As Strings	    ${output}	Complete

Verify that application pod is running
    [Documentation]	    Wait until application pod runs
    [Tags]		    pods
    [Arguments]		    ${project}
    ${pod}	Execute Command	    oc -n ${project} get pods -o name|awk \'!/build|deploy/ {sub(/pod\\//,\"\");print}\'
    Wait Until Keyword Succeeds	    5 min	5 sec	    Application pod is not ready	${project}	${pod}

Application pod exists
    [Arguments]	    ${project}
    ${pod}	Execute Comman	    doc get -n ${project} pods --no-headers |egrep -v \"build|deploy\"	    return_stdout=False	    return_rc=True
    Repeat Keyword	${pod}	    Application pod exists	${project}

Application pod is not ready
    [Arguments]	    ${project}	    ${pod}
    ${output}	    Execute Command	oc -n ${project} get pod ${pod} -o go-template --template=\'{{.status.phase}}\'
    Should Be Equal As Strings	    ${output}	    Running

Configure autoscale
    [Arguments]		${project}	${dc}	    ${min}	${max}	    ${cpu_percent}
    ${exists}	    Execute Command	oc -n ${project} get hpa ${dc}	    return_stdout=False     return_rc=True
    Run Keyword If	${exists}>0	Execute Command	    oc -n ${project} autoscale dc/${dc} --min ${min} --max ${max} --cpu-percent=${cpu_percent}
