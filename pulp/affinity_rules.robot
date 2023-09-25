*** Settings ***
Library     Process
Library     OperatingSystem
Resource    vars.robot

*** Test Cases ***

Ensure anti-affinity rules for API pods
    ${cr_affinity}    Run Process     ${get_pulp} -ojsonpath\='{.spec.api.affinity}'   stderr=STDOUT  shell=yes
    Log     ${cr_affinity.stdout}
    ${cr_affinity_json}  Evaluate    json.loads("""${cr_affinity.stdout}""")    modules=json
    Log     ${cr_affinity_json}

    
    ${pod_affinity}    Run Process     ${oc} get pods -l ${api_label} -ojsonpath\='{.items[0].spec.affinity}'   stderr=STDOUT  shell=yes
    Log     ${pod_affinity.stdout}
    ${pod_affinity_json}  Evaluate    json.loads("""${pod_affinity.stdout}""")    modules=json
    Log     ${pod_affinity_json}

    ${expected_affinity}    Get File    manifests/api_affinity.json
    ${expected_affinity_json}        Evaluate       json.loads('''${expected_affinity}''')       modules=json
    Log     ${expected_affinity_json}


    Should Be Equal     ${cr_affinity_json}  ${expected_affinity_json}
    Should Be Equal     ${pod_affinity_json}  ${expected_affinity_json}

Ensure anti-affinity rules for Content pods
    ${cr_affinity}    Run Process     ${get_pulp} -ojsonpath\='{.spec.content.affinity}'   stderr=STDOUT  shell=yes
    Log     ${cr_affinity.stdout}
    ${cr_affinity_json}  Evaluate    json.loads("""${cr_affinity.stdout}""")    modules=json
    Log     ${cr_affinity_json}


    ${pod_affinity}    Run Process     ${oc} get pods -l ${content_label} -ojsonpath\='{.items[0].spec.affinity}'   stderr=STDOUT  shell=yes
    Log     ${pod_affinity.stdout}
    ${pod_affinity_json}  Evaluate    json.loads("""${pod_affinity.stdout}""")    modules=json
    Log     ${pod_affinity_json}

    ${expected_affinity}    Get File    manifests/content_affinity.json
    ${expected_affinity_json}        Evaluate       json.loads('''${expected_affinity}''')       modules=json
    Log     ${expected_affinity_json}


    Should Be Equal     ${cr_affinity_json}  ${expected_affinity_json}
    Should Be Equal     ${pod_affinity_json}  ${expected_affinity_json}
