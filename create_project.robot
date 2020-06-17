*** Settings ***
Documentation
	...	| Teste de criação de projeto
	...	| Caso ja exista uma aplicacao em execucao o teste nao cria nada

Library		SSHLibrary
Suite Setup	Login OKD Host
Suite Teardown	Close All Connections

Resource	vars.robot

*** Variables ***
${build_name}	test-1

*** Test Cases ***
Test Host Login
    [Documentation]	    Login to okd host and send shell command
    ${output}	Execute Command	    echo \'Login ok!\'
    Should be equal	${output}   Login ok!

Test OKD Login
    [Documentation]	Login to okd and verify identity
    ${output}	    Execute Command	oc login -u ${OKD_ADMIN_USER} -p ${OKD_ADMIN_PASS} 2>&1
    Should contain  ${output}	Login successful.

Test Projects
    [Documentation]  List plataform default projects
    ${output}	    Execute Commandoc projects -q 2>&1
    Should contain  ${output}	default	kube-public kube-system	openshift

Test Create Project
    [Documentation]	Test project creation
    ...			should create a new project with name ${PROJECT_TEST} if ok
    [Tags]	project
    
    ${exists}	Execute Command	    oc project ${PROJECT_TEST}	return_stdout=False return_rc=True
    Run Keyword If  ${exists}>0	Execute Command	oc new-project ${PROJECT_TEST}	return_stdout=False     return_rc=True
    
Test Create Secret
    ${exists}	Execute Commandoc -n ${PROJECT_TEST} get secret ${Secret Name}	return_stdout=False     return_rc=True
    Run Keyword If  ${exists}>0	Execute Command	    oc -n ${PROJECT_TEST} secrets new ${Secret Name} ssh-privatekey=${Secret Key}

Test Create APP
    [Documentation]	Test app creation
    [Tags]  project app	pods	service	route

    ${exists	}Execute Command    oc -n ${PROJECT_TEST} get dc ${APP_NAME}	return_stdout=False     return_rc=True
    Run Keyword If  ${exists}>0	Execute Command	oc -n ${PROJECT_TEST} new-app ${APP_IMAGE}~${APP_SOURCE} --name ${APP_NAME} --source-secret=gitlab 2>&1

    ${output}	Execute Command	oc -n ${PROJECT_TEST} get dc ${APP_NAME}
    Should contain  ${output}	${APP_NAME}
    ${output}	Execute Command	oc -n ${PROJECT_TEST} get service ${APP_NAME}
    Should contain  ${output}	${APP_NAME}
    ${output}	Execute Command	oc -n ${PROJECT_TEST} get bc ${APP_NAME}
    Should contain  ${output	}${APP_NAME}

Test expose service creation
    [Documentation] Create route
    ${exists}	Execute Command	oc -n ${PROJECT_TEST} get route ${APP_NAME} return_stdout=False     return_rc=True
    Run Keyword If  ${exists}>0	Execute Command	oc -n ${PROJECT_TEST} expose svc ${APP_NAME}

Verify that build pod is working
    [Documentation] Wait until build pod finishes work
    [Tags]  pods
    Wait Until Keyword Succeeds	5 min	5 sec	Build pod test-1-build is not ready

Verify build status
    ${output}	Execute Command	oc -n ${PROJECT_TEST} get builds ${build_name} -o go-template --template=\'{{.status.phase}}\'
    Should Be Equal As Strings	${output}   Complete

Wait until application pod start to run deployment
    Application pod exists

Verify that application pod is running
    [Documentation] Wait until application pod runs
    [Tags]  pods
    ${pod}  Execute Command  oc -n ${PROJECT_TEST} get pods -o name|awk \'!/build|deploy/ {sub(/pod\\//,"");print}\'
    Wait Until Keyword Succeeds	5 min	5 sec	Application pod ${pod} is not ready

*** Keywords ***
Login OKD Host
    Open Connection	${OKD_HOST_ADDR}
    Login	${OKD_HOST_USER}    ${OKD_HOST_PASS}

Build pod ${pod} is not ready
    ${output}	Execute Command	    oc -n ${PROJECT_TEST} get pod ${pod} -o go-template --template=\'{{.status.phase}}\'
    Should Be Equal As Strings	${output}   Succeeded

Application pod exists
    ${pod}  Execute Comman  doc get -n ${PROJECT_TEST} pods --no-headers |egrep -v "build|deploy"   return_stdout=False		return_rc=True
    Repeat Keyword  ${pod}  Application pod exists

Application pod ${pod} is not ready
    ${output}	Execute Command	oc -n ${PROJECT_TEST} get pod ${pod} -o go-template --template=\'{{.status.phase}}\'
    Should Be Equal As Strings	${output}   Running
