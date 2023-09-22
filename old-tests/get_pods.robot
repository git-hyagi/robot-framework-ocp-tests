*** Settings ***
Library		SSHLibrary
Library		String
Library		Collections
Suite Setup	Login OKD Host
Suite Teardown	Close All Connections

Resource	vars.robot

*** Test Cases ***
Get pods
    ${pods}	Execute Commandoc -n ${PROJECT_TEST} get pods -o go-template --template='{{range .items}}{{.metadata.name}}{{"\\n"}}{{end}}'
    @{pods}	Split To Lines	    ${pods}
    Set Global Variable	    ${pods}

Print pod name
    ${pod}  Get From List   ${pods} 1

*** Keywords ***
Login OKD Host
    Open Connection	${OKD_HOST_ADDR}
    Login	${OKD_HOST_USER}	${OKD_HOST_PASS}
