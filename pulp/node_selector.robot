*** Settings ***
Library     Process
Library     OperatingSystem
Resource    vars.robot

*** Test Cases ***

Ensure worker pods have the correct nodeSelector
    ${cr_node_selector}         Run Process         ${get_pulp} -ojsonpath\='{.spec.worker.node_selector}'   stderr=STDOUT  shell=yes
    Log                         ${cr_pdb.stdout}
    ${cr_pdb_json}              Evaluate            json.loads("""${cr_pdb.stdout}""")    modules=json
    Log                         ${cr_pdb_json}

    ${nodes}                    Run Process         ${oc} get nodes -l ${worker_node_selector}    stderr=STDOUT  shell=yes
    Log                         ${nodes.stdout}
    ${nodes_json}               Evaluate            json.loads("""${nodes.stdout}""")    modules=json
    Log                         ${nodes_json}

    ${pod}                      Run Process         ${oc} get pods -l ${worker_label} -ojsonpath\='{.items[0].status.host}'   stderr=STDOUT  shell=yes
    Log     ${pod.stdout}
    ${pod}  Evaluate    json.loads("""${pod.stdout}""")    modules=json
    Log     ${pod_json}

    Should Be True             ${pod_json} in ${nodes}
#    List Should Contain Value     ${models}     train-again-v1-16k
#    Should Contain    ${models}    sourcemodel8k8020-v1-8k

