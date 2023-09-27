*** Settings ***
Library         Process
Library         OperatingSystem
Library         String
Resource        vars.robot
Resource        keywords.resource
Suite Setup     Configure Pulp

*** Test Cases ***

Start file upload
    ${ARTIFACT_HREF}            Start Process       ${pulp_cli} artifact upload --file ${TEST_FILE_PATH}       stderr=STDOUT  shell=yes  alias=upload_file
    Sleep                       5s                 Wait a little bit to make sure the containers will be recreated in the middle of the upload process

Modify image_version to simulate upgrade
    Modify image version

Wait operator sync image change task
    Wait Pulp sync tasks

Wait upload task to complete
    ${result}               Wait For Process 	upload_file

Verify file integrity (compare hash)
    ${artifact_list}        Run Process         ${pulp_cli} artifact list       stderr=STDOUT   shell=yes
    ${pulp_file_sha}        Evaluate            json.loads("""${artifact_list.stdout}""")       modules=json
    Should Be Equal         ${TEST_FILE_SHA}    ${pulp_file_sha[0]["sha256"]}

Create file content from an Artifact
    ${CONTENT_HREF}         Run Process     ${pulp_cli} file content create --relative-path ${TEST_FILE_NAME} --sha256 ${TEST_FILE_SHA}     stderr=STDOUT   shell=yes
    ${output}               Run Process     ${pulp_cli} file content show --href ${CONTENT_HREF}    stderr=STDOUT   shell=yes

Create a repository foo
    Run Process     ${pulp_cli} file repository create --name ${TEST_FILE_REPO}     stderr=STDOUT   shell=yes

Add content to repository foo
    Run Process     ${pulp_cli} file repository add --name ${TEST_FILE_REPO} --sha256 ${TEST_FILE_SHA} --relative-path ${TEST_FILE_NAME}    stderr=STDOUT   shell=yes

Create a Publication
    ${PUBLICATION_HREF}     Run Process     ${pulp_cli} file publication create --repository ${TEST_FILE_REPO} --version 1      shell=yes
    ${publication_href_json}        Evaluate            json.loads("""${PUBLICATION_HREF.stdout}""")       modules=json
    Set Global Variable        ${publication_href_json}

Create a Distribution for the Publication
    Run Process     ${pulp_cli} file distribution create --name ${TEST_FILE_DISTRIBUTION} --base-path ${TEST_FILE_REPO} --publication ${publication_href_json["pulp_href"]}     stderr=STDOUT      shell=yes


Start file download
    ${dl_task}            Start Process    curl -ksL --limit-rate 4m -o /tmp/go.tar.gz "https://${route_host}/pulp/content/${TEST_FILE_REPO}/${TEST_FILE_NAME}"       stderr=STDOUT   shell=yes     alias=download_file

Modify image_version again to simulate upgrade
    Modify image version

Wait operator re-sync image change task
    Wait Pulp sync tasks

Wait download task to complete
    ${result}               Wait For Process 	download_file

Verify dl file integrity (compare hash)
    ${pulp_file_sha}        Run Process         sha256sum /tmp/go.tar.gz|cut -d" " -f1      shell=yes
    Should Be Equal         ${pulp_file_sha.stdout}       ${TEST_FILE_SHA}



#Start repo sync task
#Wait until sync task finishes
#Verify repo integrity