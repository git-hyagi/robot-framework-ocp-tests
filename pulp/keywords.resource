*** Settings ***
Library         OperatingSystem
Resource        vars.robot


*** Keywords ***
Configure Pulp
    ${output}       Run Process     ${pulp_cli} config create --base-url https://pulp.apps.ci-ln-gib35qb-76ef8.aws-2.ci.openshift.org --username ${pulp_user} --password ${pulp_pwd} --no-verify-ssl --overwrite       stderr=STDOUT  shell=yes