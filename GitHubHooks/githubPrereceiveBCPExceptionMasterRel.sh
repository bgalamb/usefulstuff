#!/bin/bash

INFRA_PATTERN='^\[INFRA'
TEST_PATTERN='^\[TEST'
DEV_PATTERN='^\[DEV'
SAP_BCP_PATTERN='^\[BCP:'
SAPJIRAPATTERN='^\[HCPSDKASST-'


ERROR_MSG_JIRA="[POLICY] The commit doesn't reference a VALID JIRA issue"
ERROR_MSG_BCP="[POLICY] The commit doesn't reference a VALID BCP incident"

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

  #Common validation for the master and rel branches.
  if [[ $REFNAME =~ $MASTERBRANCHNAME ]] || [[ $REFNAME =~ $RELBRANCHNAME ]]; then

      echo "Entered if refname=?master refname?=rel-*"
      for COMMIT in `git rev-list $OLDREV..$NEWREV`;
      do

        RELEASE_NOTES_CHANGED=`git diff --name-only $OLDREV $NEWREV | grep -i release_notes.md`

        #echo "Commit is: [$COMMIT]"
        MESSAGE=`git cat-file commit $COMMIT | sed '1,/^$/d'`
        #echo "message is: [$MESSAGE]"
        INFRA_REF=`echo $MESSAGE | grep -i --regexp=$INFRA_PATTERN | cut -d "[" -f 2 | cut -d "]" -f 1`
        #echo "sapjira is : [$INFRA_REF]"
        TEST_REF=`echo $MESSAGE | grep -i --regexp=$TEST_PATTERN | cut -d "[" -f 2 | cut -d "]" -f 1`
        #echo "sapjira is : [$TEST_REF]"
        BCP_REF=`echo $MESSAGE | grep -i --regexp=$SAP_BCP_PATTERN | cut -d ":" -f 2 | cut -d "]" -f 1`
        #echo "bcp is : [$BCP_REF]"

        echo "MESSAGE= "$MESSAGE
        echo "INFRA_REF= "$INFRA_REF
        echo "BCP_REF= "$BCP_REF
        echo "TEST_REF= "$TEST_REF

        #Validation counter initialization
        NO_INFRA=0
        NO_BCP=0
        NO_TEST=0
        NO_DEV=0
        NO_SAP_JIRA=0

        echo "Validating Commit message for master and release branches..."

        if [ -z "$INFRA_REF" ]; then
              echo "No INFRA pattern found in message. (continue...)"
              NO_INFRA=1
        fi

        if [ -z "$TEST_REF" ]; then
              echo "No TEST pattern found in message. (continue...)"
              NO_TEST=1
        fi

        if [ -z "$BCP_REF" ]; then
              echo "No BCP pattern found in message. (continue...)"
              NO_BCP=1
        else
              echo "Referenced BCP is :$BCP_REF"
              #message seems to be valid, validate it
              # API to validate BCP : requires authentication. The cookie which is sent back in the first request has to be sent back in the 2. request.
              BCP_REF_TXT=`curl -s -u "$BCPUSERNAME:$BCPPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://support.wdf.sap.corp/sap/bc/dsi/rest/ii/read_zini?incident_id=${BCP_REF}" `
              #BCP_REF_TXT=`curl -s -u "$BCPUSERNAME:$BCPPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://support.wdf.sap.corp/sap/bc/dsi/rest/ii/read_zini?incident_id=${BCP_REF}" `
              #echo "Response from BCP [$BCP_REF_TXT]"
              echo "Server resoponse was:"
              RESPONSE=`echo $BCP_REF_TXT`
              echo $RESPONSE
              if  `echo $RESPONSE | grep -q "<MESSAGE>No incident[s]* found<\/MESSAGE>"`; then
                echo "$ERROR_MSG_BCP: $MESSAGE" >&2
                exit 1
              fi
              if  `echo $RESPONSE | grep -q "<MESSAGE>Invalid value .* entered for incident_id.<\/MESSAGE>"`; then
                echo "$ERROR_MSG_BCP: $MESSAGE" >&2
                exit 1
              fi
              # Vailating release_notes.md
              #echo "Validating release_notes.md file change"
              #if [ -z "$RELEASE_NOTES_CHANGED" ] ; then
              #  echo "You have not changed the release_notes.md file, however, you are working on a BCP incident. Please update the release_notes.md file as well!"
              #  exit 1
              #else
              #  echo "Release notes file has been changed successfully. Everything is awesome ^^!"
              #fi

              echo  "Commit message validated. No errors found!"
        fi

        #Only for master if no test, no bcp and no infra pattern found.
        if [ $(($NO_INFRA + $NO_BCP + $NO_TEST)) == 3 ] && [[ $REFNAME =~ $MASTERBRANCHNAME ]]; then
            echo "Validating only master brach related patterns..."

            DEV_REF=`echo $MESSAGE | grep -i --regexp=$DEV_PATTERN | cut -d "[" -f 2 | cut -d "]" -f 1`
            #echo "sapjira is : [$DEV_REF]"

            SAPJIRAREF=`echo $MESSAGE | grep -i --regexp=$SAPJIRAPATTERN | cut -d ":" -f 2 | cut -d "]" -f 1`
            #echo "sapjira is : [$SAPJIRAREF]"

            if [ -z "$DEV_REF" ]; then
                echo "No DEV pattern found in message. (continue...)"
                NO_DEV=1
            fi

            if [ -z "$SAPJIRAREF" ]; then
                echo "No JIRA pattern found in message? (continue...)"
                NO_SAP_JIRA=1
            else
                echo "Referenced JIRA item is :$SAPJIRAREF"
            fi
        fi

        if [[ $REFNAME =~ $RELBRANCHNAME ]] && [[ $(($NO_INFRA + $NO_BCP + $NO_TEST)) == 3 ]]; then
              echo "*********************************************************************"
              echo "The validation of your commit message failed!"
              echo "Please use the following formats:"
              echo "eg: [BCP:1770413430] Terrible crash has been fixed."
              echo "eg: [TEST] UI test fix."
              echo "eg: [INFRA] Updating dependencies."
              echo "*********************************************************************"
              exit -1
        elif [[ $REFNAME =~ $MASTERBRANCHNAME ]] && [[ $(($NO_INFRA + $NO_BCP + $NO_TEST + $NO_DEV + $NO_SAP_JIRA)) == 5 ]]; then
              echo "*********************************************************************"
              echo "The validation of your commit message failed!"
              echo "Please use the following formats:"
              echo "eg: [BCP:1770413430] Terrible crash has been fixed."
              echo "eg: [TEST] UI test fix."
              echo "eg: [INFRA] Updating dependencies."
              echo "eg: [DEV] Some minor enhancements."
              echo "eg: [HCPSDKASST-130] Random JIRA item description."
              echo "*********************************************************************"
              exit -1
        fi
      done
    fi
    echo "Commit message validated. No errors found!"
done
echo "loop done"
exit 0
