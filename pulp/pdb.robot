*** Settings ***
Library     Process
Library     OperatingSystem
Resource    vars.robot

*** Test Cases ***

Ensure PDB is correctly defined fot API pods
    ${cr_pdb}       Run Process     ${get_pulp} -ojsonpath\='{.spec.api.pdb}'   stderr=STDOUT  shell=yes
    Log             ${cr_pdb.stdout}
    ${cr_pdb_json}  Evaluate        json.loads("""${cr_pdb.stdout}""")    modules=json
    Log             ${cr_pdb_json}

    ${pdb}          Run Process     ${oc} get pdb ${api_pdb_name} -ojsonpath\='{.status}'   stderr=STDOUT  shell=yes
    Log             ${pdb.stdout}
    ${pdb_json}     Evaluate        json.loads("""${pdb.stdout}""")    modules=json
    Log             ${pdb_json}

    ${disruptions_allowed}      Evaluate                            ${api_replicas} - 3
    Should Be Equal             ${api_min_available}                ${cr_pdb_json["minAvailable"]}
    Should Be Equal             ${pdb_json["desiredHealthy"]}       ${cr_pdb_json["minAvailable"]}
    Should Be Equal             ${pdb_json["disruptionsAllowed"]}   ${disruptions_allowed}


Ensure PDB is correctly defined fot Content pods
    ${cr_pdb}           Run Process         ${get_pulp} -ojsonpath\='{.spec.content.pdb}'   stderr=STDOUT  shell=yes
    Log                 ${cr_pdb.stdout}
    ${cr_pdb_json}      Evaluate            json.loads("""${cr_pdb.stdout}""")    modules=json
    Log                 ${cr_pdb_json}

    ${pdb}          Run Process         ${oc} get pdb ${content_pdb_name} -ojsonpath\='{.status}'   stderr=STDOUT  shell=yes
    Log             ${pdb.stdout}
    ${pdb_json}     Evaluate            json.loads("""${pdb.stdout}""")    modules=json
    Log             ${pdb_json}

    ${disruptions_allowed}      Evaluate                ${content_replicas} // 2
    ${max_unavailable}          Evaluate                ${pdb_json["desiredHealthy"]} / ${pdb_json["expectedPods"]} * 100
    ${max_unavailable}          Convert To Integer      ${max_unavailable}
    ${max_unavailable}          Convert To String       ${max_unavailable}%

    Should Be Equal     ${content_max_unavailable}          ${max_unavailable}
    Should Be Equal     ${pdb_json["desiredHealthy"]}       ${disruptions_allowed}
    Should Be Equal     ${pdb_json["disruptionsAllowed"]}   ${disruptions_allowed}


Ensure PDB is correctly defined fot Worker pods
    ${cr_pdb}           Run Process         ${get_pulp} -ojsonpath\='{.spec.worker.pdb}'   stderr=STDOUT  shell=yes
    Log                 ${cr_pdb.stdout}
    ${cr_pdb_json}      Evaluate            json.loads("""${cr_pdb.stdout}""")    modules=json
    Log                 ${cr_pdb_json}

    ${pdb}              Run Process         ${oc} get pdb ${worker_pdb_name} -ojsonpath\='{.status}'   stderr=STDOUT  shell=yes
    Log                 ${pdb.stdout}
    ${pdb_json}         Evaluate            json.loads("""${pdb.stdout}""")    modules=json
    Log                 ${pdb_json}

    ${disruptions_allowed}      Evaluate       ${worker_replicas} - ${worker_min_available}

    Should Be Equal             ${pdb_json["desiredHealthy"]}  ${worker_min_available}
    Should Be Equal             ${pdb_json["disruptionsAllowed"]}  ${disruptions_allowed}
