SAPJIRAPATTERN='^\[JIRA:'
SAPBCPPATTERN='^\[BCP:'

JIRAUSERNAME="i040023"
JIRAPASSWORD=""

BCPUSERNAME="GIT_ZINI"
BCPPASSWORD="PRSs%MffF7PFlEtkYbFtlVEMcCehYwtakwndvlaY"

ERROR_MSG_JIRA="[POLICY] The commit doesn't reference a VALID JIRA issue"
ERROR_MSG_BCP="[POLICY] The commit doesn't reference a VALID BCP incident"


SAPJIRAREF=`echo $event_payload_pull_request_title | grep -i --regexp=$SAPJIRAPATTERN | cut -d ":" -f 2 | cut -d "]" -f 1`
#echo "sapjira is : [$SAPJIRAREF]"

BCPREF=`echo $event_payload_pull_request_title | grep -i --regexp=$SAPBCPPATTERN | cut -d ":" -f 2 | cut -d "]" -f 1`
#echo "bcp is : [$BCPREF]"



NO_SAP_JIRA=0
NO_BCP=0

echo "Validating Commit message..."

if [ -z "$SAPJIRAREF" ]; then
      NO_SAP_JIRA=1
else
      echo "Referenced jira is :$SAPJIRAREF"
      JIRAREFTXT=`curl -s -u "$JIRAUSERNAME:$JIRAPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://sapjira.wdf.sap.corp/rest/api/latest/issue/$SAPJIRAREF"`
      if `echo $BCPREFTXT | grep "Issue Does Not Exist"` ; then
        echo "$ERROR_MSG_BCP: $MESSAGE" >&2
        exit 1
      fi
fi

if [ -z "$BCPREF" ]; then
      NO_BCP=1
else
      #message seems to be valid, validate it
      # API to validate BCP : requires authentication. The cookie which is sent back in the first request has to be sent back in the 2. request.
      BCPREFTXT=`curl -s -u "$BCPUSERNAME:$BCPPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://support.wdf.sap.corp/sap/bc/dsi/rest/ii/read_zini?incident_id=${BCPREF}" `
      BCPREFTXT=`curl -s -u "$BCPUSERNAME:$BCPPASSWORD" -c ./cookies.txt -b ./cookies.txt "https://support.wdf.sap.corp/sap/bc/dsi/rest/ii/read_zini?incident_id=${BCPREF}" `
      #echo "Response from BCP [$BCPREFTXT]"
      if  `echo $BCPREFTXT | grep -q "No incident found"`; then
        echo "$ERROR_MSG_BCP: $MESSAGE" >&2
        exit 1
      fi
      if  `echo $BCPREFTXT | grep -q "Invalid value id must be 10 digits entered for incident_id."`; then
        echo "$ERROR_MSG_BCP: $MESSAGE" >&2
        exit 1
      fi
      echo  "Commit message validated. No errors found!"
fi

if [ $(($NO_SAP_JIRA + $NO_BCP)) == 2 ]; then
      echo "*********************************************************************"
      echo "You did not provide neither SAPJIRA nor BCP in your commit message!!"
      echo "Please use the following format:"
      echo "eg: [BCP:770413430] Fix for the terrible crash"
      echo "eg: [JIRA:HCPSDKFOUND-351] Fix Some error I made in the code"
      echo "*********************************************************************"
      exit -1
fi
