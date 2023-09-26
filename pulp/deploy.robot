*** Settings ***
Library     Process
Library     OperatingSystem
Resource    vars.robot

*** Test Cases ***

Create Pulp project
    Run Process         /usr/bin/oc new-project pulp    stderr=STDOUT  shell=yes

Deploy Database
    Run Process         /bin/sh scripts/install_db.sh    stderr=STDOUT  shell=yes

Deploy Minio
    Run Process         /bin/sh scripts/install_minio.sh    stderr=STDOUT  shell=yes

Deploy Pulp
    # pending make deploy
    Run Process         /bin/sh scripts/deploy_pulp.sh    stderr=STDOUT  shell=yes

Configure Pulp HA
    Run Process         /bin/sh scripts/pulp_ha.sh    stderr=STDOUT  shell=yes