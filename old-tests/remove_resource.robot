*** Settings ***
Library		SSHLibrary
Suite Setup	Login OKD Host
Suite Teardown	Close All Connections

Resource	vars.robot

*** Test Cases ***
Test Remove App
    [Documentation]	Remove everything with tag app=${APP_NAME}
    [Tags]		remove	app pods    services
    ${rc}		Execute Command	    oc -n ${PROJECT_TEST} delete all -l app=${APP_NAME}	    return_stdout=False	    return_rc=True
    Should Be True	${rc}==0

Test Remove Secret
    [Documentation]	Remove secret ${Secret Name}
    [Tags]		remove	app pods    services
    ${rc}	Execute Command	    oc -n ${PROJECT_TEST} delete secret ${Secret Name}	    return_stdout=False	    return_rc=True
    Should Be True	${rc}==0

Test Remove Project
    [Documentation]	Test project deletion
    ...			should remove ${PROJECT_TEST} if ok
    [Tags]	    project
    ${output}	    Execute Commandoc delete project ${PROJECT_TEST} 2>&1
    Should contain	${output}"${PROJECT_TEST}" deleted

*** Keywords ***
Login OKD Host
    Open Connection	${OKD_HOST_ADDR}
    Login	${OKD_HOST_USER}	${OKD_HOST_PASS}
