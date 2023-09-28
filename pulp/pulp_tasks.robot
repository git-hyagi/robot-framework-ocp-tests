*** Settings ***
Library         Process
Library         OperatingSystem
Library         String
Resource        vars.robot
Resource        keywords.resource
Suite Setup     Configure Pulp

*** Test Cases ***

################################################################################################################################
# UPLOAD ARTIFACT TEST
################################################################################################################################
Start file upload
    [tags]      upload-test
    ${ARTIFACT_HREF}            Start Process       ${pulp_cli} artifact upload --file ${TEST_FILE_PATH}       stderr=STDOUT  shell=yes  alias=upload_file
    Sleep                       5s                 Wait a little bit to make sure the containers will be recreated in the middle of the upload process

Modify image_version to simulate upgrade
    [tags]      upload-test
    Modify image version

Wait operator sync image change task
    [tags]      upload-test
    Wait Pulp sync tasks

Wait upload task to complete
    [tags]      upload-test
    ${result}               Wait For Process 	upload_file

Verify file integrity (compare hash)
    [tags]      upload-test
    ${artifact_list}        Run Process         ${pulp_cli} artifact list       stderr=STDOUT   shell=yes
    ${pulp_file_sha}        Evaluate            json.loads("""${artifact_list.stdout}""")       modules=json
    Should Be Equal         ${TEST_FILE_SHA}    ${pulp_file_sha[0]["sha256"]}


################################################################################################################################
# PREP ENV TO DL FILE TEST
################################################################################################################################
Create file content from an Artifact
    [tags]      dl-test
    ${CONTENT_HREF}         Run Process     ${pulp_cli} file content create --relative-path ${TEST_FILE_NAME} --sha256 ${TEST_FILE_SHA}     stderr=STDOUT   shell=yes
    ${output}               Run Process     ${pulp_cli} file content show --href ${CONTENT_HREF}    stderr=STDOUT   shell=yes

Create a repository foo
    [tags]      dl-test
    Run Process     ${pulp_cli} file repository create --name ${TEST_FILE_REPO}     stderr=STDOUT   shell=yes

Add content to repository foo
    [tags]      dl-test
    Run Process     ${pulp_cli} file repository add --name ${TEST_FILE_REPO} --sha256 ${TEST_FILE_SHA} --relative-path ${TEST_FILE_NAME}    stderr=STDOUT   shell=yes

Create a Publication
    [tags]      dl-test
    ${PUBLICATION_HREF}     Run Process     ${pulp_cli} file publication create --repository ${TEST_FILE_REPO} --version 1      shell=yes
    ${publication_href_json}        Evaluate            json.loads("""${PUBLICATION_HREF.stdout}""")       modules=json
    Set Global Variable        ${publication_href_json}

Create a Distribution for the Publication
    [tags]      dl-test
    Run Process     ${pulp_cli} file distribution create --name ${TEST_FILE_DISTRIBUTION} --base-path ${TEST_FILE_REPO} --publication ${publication_href_json["pulp_href"]}     stderr=STDOUT      shell=yes


################################################################################################################################
# DL FILE TEST
################################################################################################################################

Start file download
    [tags]      dl-test
    ${dl_task}            Start Process    curl -ksL --limit-rate 4m -o /tmp/go.tar.gz "https://${route_host}/pulp/content/${TEST_FILE_REPO}/${TEST_FILE_NAME}"       stderr=STDOUT   shell=yes     alias=download_file

Modify image_version again to simulate upgrade
    [tags]      dl-test
    Modify image version

Wait operator re-sync image change task
    [tags]      dl-test
    Wait Pulp sync tasks

Wait download task to complete
    [tags]      dl-test
    ${result}               Wait For Process 	download_file

Verify dl file integrity (compare hash)
    [tags]      dl-test
    ${pulp_file_sha}        Run Process         sha256sum /tmp/go.tar.gz|cut -d" " -f1      shell=yes
    Should Be Equal         ${pulp_file_sha.stdout}       ${TEST_FILE_SHA}


################################################################################################################################
# SYNC RPM REPO TEST
################################################################################################################################
Create a repository to sync task
    [tags]      repo-sync
    Run Process     ${pulp_cli} rpm repository create --name sync-repo     stderr=STDOUT   shell=yes

Create a new remote bar
    [tags]      repo-sync
    Run Process      ${pulp_cli} rpm remote create --name bar --url ${TEST_REPO_SYNC} --policy 'on_demand'      shell=yes

Sync repository using remote bar
    [tags]      repo-sync
    Run Process         ${pulp_cli} rpm repository update --name sync-repo --remote bar        shell=yes
    ${output}           Start Process    ${pulp_cli} rpm repository sync --name sync-repo      shell=yes     alias=sync-repo    stderr=STDOUT
    ${sync_task}        Run Process     awk '{print $4}'     shell=yes   stdin=${output.stdout}
    Set Global Variable        ${sync_task}     ${sync_task.stdout}

Modify image_version again to simulate upgrade [sync-repo]
    [tags]      repo-sync
    Modify image version

Wait operator sync-repo image change task
    [tags]      repo-sync
    Wait Pulp sync tasks

Wait repo-sync task to complete
    [tags]      repo-sync
    ${result}               Wait For Process 	sync-repo

Verify repo-sync integrity
    [tags]      repo-sync
    ${output}                Run Process         ${pulp_cli} show --href ${sync_task}    shell=yes
    ${sync_task_json}        Evaluate            json.loads("""${output.stdout}""")       modules=json
    Should Be Equal          ${sync_task_json["state"]}       completed
