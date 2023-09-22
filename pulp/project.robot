*** Settings ***
Library     Process
Resource    vars.robot

*** Test Cases ***

Pulp project exists
    ${result}    Run Process     ${oc} get project ${project_name} -ojsonpath\='{.status.phase}'   stderr=STDOUT  shell=yes
    Should Be Equal     ${result.stdout}    Active
