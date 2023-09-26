*** Settings ***
Library     Process
Library     OperatingSystem
Library     String
Resource    vars.robot

*** Test Cases ***

Ensure worker pods have the correct nodeSelector
    ${cr_node_selector}         Run Process         ${get_pulp} -ojsonpath\='{.spec.worker.node_selector}'   stderr=STDOUT  shell=yes
    Log                         ${cr_node_selector.stdout}
    ${cr_node_selector_json}    Evaluate            json.loads("""${cr_node_selector.stdout}""")    modules=json
    Log                         ${cr_node_selector_json}

    ${nodes}                    Run Process         ${oc} get nodes -l ${worker_node_selector} -ojsonpath\='{.items[*].status.addresses[0].address}'    stderr=STDOUT  shell=yes
    Log                         ${nodes.stdout}
    @{nodes}                    Split String        ${nodes.stdout}
    Log Many                    @{nodes}

    ${pod_node}                      Run Process         ${oc} get pods -l ${worker_label} -ojsonpath\='{.items[0].status.hostIP}'   stderr=STDOUT  shell=yes
    Log     ${pod_node.stdout}

    Set Local Variable    ${found_node}       ${False}
    FOR     ${NODE}     IN      @{nodes}
        IF  $pod_node.stdout == $NODE
            Set Local Variable      ${found_node}       ${True}
        END
    END

    Should Be True             ${found_node}
