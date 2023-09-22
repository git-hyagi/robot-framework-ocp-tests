*** Settings ***
Documentation
      ...   | Teste de comunicao usando ovs-subnet
      ...   | - entre pods do mesmo projeto
      ...   | - entre pods e service ips
      ...   | - entre pods e service names
      ...   | - entre pods e routes
      ...   | - de um host para um route

Library		    SSHLibrary
Library		    OperatingSystem
Suite SetupLogin    OKD Host
Suite Teardown	    Close All Connections

Resource	    vars.robot


*** Variables ***
${src_pod_ip}	    10.128.1.225
${src_pod_name}	    test-1-5qnsp
${dst_pod_ip}	    10.128.1.226
${dst_pod_name}	    test-1-d6xlb
${service_ip}	    172.30.51.253
${service_port}	    8080
${service_address}  test.temp.svc
${route_address}    http://test-temp.ocp311.lab 


*** Test Cases ***
Test communication
    [Documentation]
    	...	| Network tests
    
    Between pods (same project)
    Between pods and services (by ip)
    Between pods and services (by name)
    Between pods and routers
    From outside cluster to route

*** Keywords ***
Login OKD Host
    Open Connection ${OKD_HOST_ADDR}
    Login	    ${OKD_HOST_USER}	${OKD_HOST_PASS}

Between pods (same project)
    ${output}	Execute Commandoc -n ${PROJECT_TEST} rsh ${src_pod_name} ping ${dst_pod_ip} -c 1
    Should Contain  ${output}	0% packet loss

Between pods and services (by ip)
    ${output}	Execute Command	oc -n ${PROJECT_TEST} rsh ${src_pod_name} curl ${service_ip}:${service_port}
    Should Contain  ${output}	It Works!

Between pods and services (by name)
    ${output}	Execute Command	oc -n ${PROJECT_TEST} rsh ${src_pod_name} curl ${service_address}:${service_port}
    Should Contain  ${output}	It Works!

Between pods and routers
    ${output}	Execute Command	oc -n ${PROJECT_TEST} rsh ${src_pod_name} curl ${route_address}
    Should Contain  ${output}	It Works!

From outside cluster to route
    ${output}	Run curl ${route_address}
    Should Contain  ${output}	It Works!
