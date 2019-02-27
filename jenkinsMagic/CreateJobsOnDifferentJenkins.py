# before executing make sure to have the list of jobs already added to jobNames.txt

import subprocess
import shutil
import os

filepath = 'jobNames.txt'
localjenkinsurl=""
remotejenkinsurl=""
jenkinsUser_Old = ""
userApitoken_Old = ""
jenkinsUser_New = ""
userApitoken_New = ""

def checkError(returnCode, errorMessage):
    if returnCode != 0:
        raise Exception(errorMessage)

#get the CLI jars
#get and rename
retCode = subprocess.call(["curl","-O", remotejenkinsurl+"/jnlpJars/jenkins-cli.jar"])
checkError(retCode, "Getting jenkins cli.jar failed")
retCode = subprocess.call(["mv","jenkins-cli.jar","jenkins-cli-new.jar"])
checkError(retCode, "moving jenkins cli.jar failed")
print('done')


#get
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
      jenkinsclicommand = ["java","-jar", "jenkins-cli.jar","-s",localjenkinsurl,"-auth", "jenkins:8048628f407f2c4aca1a16d1bc4066d0", "get-job",line]
      print(jenkinsclicommand)
      retCode = subprocess.call(jenkinsclicommand, stdout=fp2)
      checkError(retCode, "Getting job definition failed")
      fp2.close()

      #create new jobs
      fp3 = open(jobdefinitionfilename, "r")
      print("Creating job based on the definition for {}".format(line))

      jenkinsclicommand = ["java","-jar", "jenkins-cli-new.jar","-s",remotejenkinsurl,"-auth", "i040023:115b75702399fec3db1276de0b1080f9d7", "create-job",line]
      print(jenkinsclicommand)
      retCode = subprocess.call(jenkinsclicommand, stdin=fp3)
      checkError(retCode, "Getting job definition failed")
      fp3.close()
