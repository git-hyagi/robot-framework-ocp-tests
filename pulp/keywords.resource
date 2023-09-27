*** Settings ***
Library         OperatingSystem
Resource        vars.robot


*** Keywords ***

Configure Pulp
    ${default_domain}       Run Process         /usr/bin/oc -n openshift-ingress-operator get ingresscontrollers default -ojsonpath\='{.status.domain}'        stderr=STDOUT  shell=yes
    Set Global Variable     ${default_domain}
    ${route_host}           Catenate        SEPARATOR=      pulp.   ${default_domain.stdout}
    Set Global Variable     ${route_host}

    ${output}       Run Process     ${pulp_cli} config create --base-url https://pulp.${default_domain.stdout} --username ${pulp_user} --password ${pulp_pwd} --no-verify-ssl --overwrite       stderr=STDOUT  shell=yes

Wait Pulp sync tasks
    Run Process             ${oc} wait --for condition\=Pulp-Operator-Finished-Execution pulp/${pulp_resource_name} --timeout\=900s         stderr=STDOUT  shell=yes


Modify image version
    ${current_image_version}        Run Process     ${oc} get pulp ${pulp_resource_name} -ojsonpath\='{.spec.image_version}'    stderr=STDOUT   shell=yes
    IF      "${current_image_version.stdout}" == "stable"
        ${image_version}        Set Variable    latest
    ELSE
        ${image_version}        Set Variable    stable
    END
    Run Process             ${oc} patch pulp ${pulp_resource_name} --type merge -p '{"spec": {"image_version": "${image_version}", "image_web_version": "${image_version}" }}'        stderr=STDOUT  shell=yes
    Sleep                       5s                 Wait a little bit to make sure the operator's status is updated