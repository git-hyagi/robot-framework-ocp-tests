*** Settings ***
Resource    vars.robot
Resource    credentials.robot

Library			SSHLibrary
Suite SetupLogin	OKD Host
Suite TeardownClose	All Connections

*** Variables ***
${Regex_APP}	    (APP|app)\\-[a-zA-Z0-9]+\\-[a-zA-Z0-9]+
${Regex_Group}	    GROUP_PAAS_[a-zA-Z0-9]+
${Regex_Quota_MEM}  \\d+(G|g|M|m)i?
${Regex_Quota_CPU}  \\d+

*** Test Cases ***
Nome do Projeto
    [Documentation]
	...	| Segue padr�o de nome de reposit�rio para imagens Docker no Artfactory. ref: [PaaS] 4.3 - Modelo de Configura��o do Artifactory.
    	...	|  * <Holding> � o nome da empresa;
    	...	|  * <Sigla> � a sigla atrelada ao Projeto. Havendo mais de uma Sigla, recomendamos que seja a Sigla Principal do Projeto;
    	...	|  * <Nome da aplica��o> � o nome atribu�do aplica��o.
    	...	| Exemplo: app-a99-pagamentos.
    Should Match Regexp	${Nome do Projeto}  ${Regex_APP}

Nome do grupo de AD
    [Documentation]
	...   | "CLOUD" � a Comunidade
    	...   | "OPENSHIFT" � a Ferramenta
    	...   | "PAAS" � o produto
    	...   | <SIGLA> � a sigla atrelada ao Projeto. Havendo mais de uma Sigla, recomendamos que seja a Sigla Principal do Projeto;
    Should Match Regexp	${Nome do Grupo de AD}	${Regex_Group}

Quota do projeto
    [Documentation]
    ...	    | Quantidade de recursos necess�rios, que devem ser definidos pelo usu�rio de acordo com as caracter�sticas do Projeto / aplica��o.
    ...	    | Evolu��o da Plataforma
    ...	    | 1. Com a experimenta��o dos clientes, avaliar a necessidade de estabelecer limite de recurso por Projeto / Container;
    ...	    | 2. Estudar sobre limits no material do Openshift;
    ...	    | 3. Inserir recomenda��es no Manual de Boas Pr�ticas.
    Should Match Regexp	${Quota Memoria}    ${Regex_Quota_MEM}
    Should Match Regexp	${Quota CPU}	${Regex_Quota_CPU}

Verifica se projeto esta criado
    ${rc}   Execute Command oc project ${Nome do Projeto}   return_stdout=False	return_rc=True
    Should Be True  ${rc} == 0

Verifica se quota de CPU esta configurada
    ${output}	Execute Command	oc -n ${Nome do Projeto} get quota ${Nome da Quota} -o go-template --template='{{index .spec.hard "limits.cpu" }}'
    Should Be True  ${output} == ${Quota CPU}

Verifica se quota de Memoria esta configurada
    ${output}	Execute Command	oc -n ${Nome do Projeto} get quota ${Nome da Quota} -o go-template --template='{{index .spec.hard "limits.memory" }}'
    Should Be Equal As Strings	${output}   ${Quota Memoria}

*** Keywords ***
Login OKD Host
    Open Connection ${OKD_HOST_ADDR}
    Login   ${OKD_HOST_USER}	${OKD_HOST_PASS}
