#!/bin/bash

SAPJIRAPATTERN='^\[JIRA:'
SAPBCPPATTERN='^\[BCP:'
INFRA_PATTERN='^\[INFRA'

ERROR_MSG_JIRA="[POLICY] The commit doesn't reference a VALID JIRA issue"
ERROR_MSG_BCP="[POLICY] The commit doesn't reference a VALID BCP incident"
ERROR_MSG_INFRA="[POLICY] The commit doesn't reference a INFRA tag"

MASTERBRANCHNAME="refs/heads/master"
RELBRANCHNAME="refs/heads/rel-.*$"

JIRAUSERNAME="i040023"
JIRAPASSWORD=""

BCPUSERNAME="GIT_ZINI"
BCPPASSWORD="PRSs%MffF7PFlEtkYbFtlVEMcCehYwtakwndvlaY"

#081801bf07e29a879975b7c759f081277e818fea 318e52c43f9d0861494ba75e7f82482a31ef0cb9 master

while read OLDREV NEWREV REFNAME ; do
  #investigate if the check can be limited to PRs which are currently merged to master,rel-2.0 branches.
  #(should not validate commits on dev branches)
  echo "OLDREV= "$OLDREV
  echo "NEWREV= "$NEWREV
  echo "REFNAME= "$REFNAME

  if [[ $REFNAME =~ $MASTERBRANCHNAME ]] || [[ $REFNAME =~ $RELBRANCHNAME ]]; then
      echo "Entered if refname=?master refname?=rel-*"
      for COMMIT in `git rev-list $OLDREV..$NEWREV`;
      do
        #echo "Commit is: [$COMMIT]"
        MESSAGE=`git cat-file commit $COMMIT | sed '1,/^$/d'`
        #echo "message is: [$MESSAGE]"
        SAPJIRAREF=`echo $MESSAGE | grep -i --regexp=$SAPJIRAPATTERN | cut -d ":" -f 2 | cut -d "]" -f 1`
        #echo "sapjira is : [$SAPJIRAREF]"
        BCPREF=`echo $MESSAGE | grep -i --regexp=$SAPBCPPATTERN | cut -d ":" -f 2 | cut -d "]" -f 1`
        #echo "bcp is : [$BCPREF]"
        INFRA_REF=`echo $MESSAGE | grep -i --regexp=$INFRA_PATTERN | cut -d "[" -f 2 | cut -d "]" -f 1`

        echo "MESSAGE= "$MESSAGE
        echo "SAPJIRAREF= "$SAPJIRAREF
        echo "BCPREF= "$BCPREF

        NO_SAP_JIRA=0
        NO_BCP=0
        NO_INFRA=0

        echo "Validating Commit message..."

        if [ -z "$INFRA_REF" ]; then
              echo "No INFRA pattern found in message. (continue...)"
              NO_INFRA=1
        fi

        if [ -z "$SAPJIRAREF" ]; then
              echo "No JIRA in message? (continue...)"
              NO_SAP_JIRA=1
        else
              echo "Referenced JIRA is :$SAPJIRAREF"
              #JIRAREFTXT=`curl -s -u "$JIRAUSERNAME:$JIRAPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://sapjira.wdf.sap.corp/rest/api/latest/issue/$SAPJIRAREF"`
              #if `echo $BCPREFTXT | grep "Issue Does Not Exist"` ; then
              #  echo "$ERROR_MSG_BCP: $MESSAGE" >&2
              #  exit 1
              #fi
        fi

        if [ -z "$BCPREF" ]; then
              echo "No BCP in message? (continue...)"
              NO_BCP=1
        else
              echo "Referenced BCP is :$BCPREF"
              #message seems to be valid, validate it
              # API to validate BCP : requires authentication. The cookie which is sent back in the first request has to be sent back in the 2. request.
              BCPREFTXT=`curl -s -u "$BCPUSERNAME:$BCPPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://support.wdf.sap.corp/sap/bc/dsi/rest/ii/read_zini?incident_id=${BCPREF}" `
              #BCPREFTXT=`curl -s -u "$BCPUSERNAME:$BCPPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://support.wdf.sap.corp/sap/bc/dsi/rest/ii/read_zini?incident_id=${BCPREF}" `

              echo "Server resoponse was:"
              RESPONSE=`echo $BCPREFTXT`
              echo $RESPONSE

              if  `echo $RESPONSE | grep -q "<MESSAGE>No incident[s]* found<\/MESSAGE>"`; then
                echo "$ERROR_MSG_BCP: $MESSAGE" >&2
                exit 1
              fi
              if  `echo $RESPONSE | grep -q "<MESSAGE>Invalid value .* entered for incident_id.<\/MESSAGE>"`; then
                echo "$ERROR_MSG_BCP: $MESSAGE" >&2
                exit 1
              fi

              echo  "Commit message validated. No errors found!"
        fi

        if [ $(($NO_SAP_JIRA + $NO_BCP + $NO_INFRA)) == 3 ]; then
              echo "*********************************************************************"
              echo "You did not provide neither JIRA nor BCP in your commit message!!"
              echo "Please use the following format:"
              echo "eg: [BCP:1770413430] Terrible crash has been fixed"
              echo "eg: [JIRA:HCPSDKFOUND-351] Develop Beer fridge logic, new requirement"
              echo "eg: [INFRA] update version"
              echo "*********************************************************************"
              exit -1
        fi

      done
    fi
    echo "loop done"
done
echo "Commit message validated. No errors found!"
exit 0
