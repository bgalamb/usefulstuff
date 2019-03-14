As a requirement we wanted all commit messages which go to the rel-* or master branches to fulfill the following patter :
[BCP:770413430] Fix for the terrible crash.
[JIRA:HCPSDKFOUND-351] implement new feature.
[EXCEPTION] there was no requirement.

The following hooks have been created :
* githubPrereceiveBCPExceptionMasterRel.sh which checks for BCP and Exception references.
* githubPrereceiveBCPJIRAMasterRel.sh checks for BCP and JIRA references.
* jenkins_bcpjiravalidator.sh in case you want to add BCP and JIRA validation as part of pre build step in jenkins.
