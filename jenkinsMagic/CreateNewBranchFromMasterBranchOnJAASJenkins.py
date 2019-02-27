# before executing make sure to have the list of jobs already added to jobNames.txt

import subprocess
import shutil
import os

newRelease = "rel-3.1"
filepath = 'jobNames.txt'
localjenkinsurl=""
jenkinsUser = ""
userApitoken = ""


def checkError(returnCode, errorMessage):
    if returnCode != 0:
        raise Exception(errorMessage)

retCode = subprocess.call(["curl","-O", localjenkinsurl+"/jnlpJars/jenkins-cli.jar"])
checkError(retCode, "Getting jenkins cli.jar failed")
print('done')

#cleanup
if os.path.exists("jenkinsJobDefinitions"):
    shutil.rmtree('jenkinsJobDefinitions')
    print("temp directory deleted")

os.makedirs("jenkinsJobDefinitions")
print("temp directory created")

with open(filepath) as fp:
    for line in fp:
      line = line.strip()
      print("Processing jenkins job {}".format(line))

      jobdefinitionfilename = "jenkinsJobDefinitions/"+line+".xml"
      fp2 = open(jobdefinitionfilename, "w")
      print("Getting job definition for {}".format(line))
      jenkinsclicommand = ["java","-jar", "jenkins-cli-new.jar","-s",localjenkinsurl,"-auth", jenkinsUser+":"+userApitoken, "get-job",line]
      print(jenkinsclicommand)
      retCode = subprocess.call(jenkinsclicommand, stdout=fp2)
      checkError(retCode, "Getting job definition failed")

      #replace the branch in the file
      print("Replace git branch in the job definition for {}".format(line))
      sedcommand = ["sed","-i","","s/\*\/master/\*\/"+newRelease+"/g", jobdefinitionfilename]
      print(sedcommand)
      retCode = subprocess.call(sedcommand)
      checkError(retCode, "Replace branch in definition file failed")
      fp2.close()

      #for logging only
      line=line.replace("Master","Rel3.1")

      #create new jobs
      fp3 = open(jobdefinitionfilename, "r")

      print("Creating job based on the definition for {}".format(line))

      jenkinsclicommand = ["java","-jar", "jenkins-cli-new.jar","-s",localjenkinsurl,"-auth", jenkinsUser+":"+userApitoken, "create-job",line]
      print(jenkinsclicommand)
      retCode = subprocess.call(jenkinsclicommand, stdin=fp3)
      checkError(retCode, "Getting job definition failed")
      fp3.close()
