*** Settings ***
Documentation
...	| Teste de scale manual de um deployment config

Resource	vars.robot
Resource	credentials.robot
Resource	openshift.robot

Library		SSHLibrary
Suite Setup	Login OKD Host
Suite Teardown	Close All Connections

*** Variables ***
${dc_name}	test
${replicas}	5

*** Test Cases ***
Verify if dc exists
    ${rc}   Execute Command	oc -n ${PROJECT_TEST} get dc ${dc_name}	    return_stdout=False	    return_rc=True
    Should Be True  ${rc} == 0

Scale Application ${APP_NAME}
    ${output}	Execute Commandoc -n ${PROJECT_TEST} scale --replicas=${replicas} dc ${dc_name}
    Should Contain	${output}	${dc_name}   scaled

Test if pods were created
    Wait Until Keyword Succeeds	    5 min	5 sec	    Wait until replicas done

*** Keywords ***
Login OKD Host
    Open Connection	${OKD_HOST_ADDR}
    Login	${OKD_HOST_USER}    ${OKD_HOST_PASS}

Wait until replicas done
    ${output}	    Execute Commandoc -n ${PROJECT_TEST} get dc ${dc_name} -o go-template --template='{{.status.readyReplicas}}'
    Should Be Equal	${output}	${replicas}
