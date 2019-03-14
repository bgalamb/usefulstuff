import requests
from requests.auth import HTTPDigestAuth
import json

# Replace with the correct URL

#baseurls =  ["https://mobileint-wd80e32cf.int.sap.hana.ondemand.com/"]#,
#baseurls  = ["https://mobilepiat-a8972607a.hana.ondemand.com/"],
#baseurls  = ["https://mobileval-wd80e32cf.int.sap.hana.ondemand.com/"]
#baseurls  = ["https://mobilestg-a8972607a.hana.ondemand.com/"],
baseurls  = ["https://mobileint-we2c9a90d.int.sap.hana.ondemand.com/"]
#baseurls  = ["https://mobileval-we2c9a90d.int.sap.hana.ondemand.com/"]



apiurl = "mobileservices/origin/hcpms/mbaas/v1/odata/admin/ApplicationSet"
headers = {"Authorization":"Basic aTA0MDAyMzpzZEZHMTIzNA=="}

def deleteApps():
    for url in baseurls:
        myResponse = requests.get(url+apiurl,headers=headers)
        jsonResponse = myResponse.json()
        #print (jsonResponse)

        # For successful API call, response code will be 200 (OK)
        if(myResponse.ok):
         print(type(jsonResponse))
         for application in jsonResponse["value"]:
           print("---------------------------------")
           print("Checking app...")
           print("AppId= "+application["ApplicationId"])
           print("DisplayName= "+application["DisplayName"])
           if "com.sap.test.oauthcreation" not in str(application["ApplicationId"]) and (str(application["ApplicationId"]).startswith("com.sap.") or str(application["ApplicationId"]).startswith("com.afariaeng.")):
               print("verdict: leave it!")
               continue
           else:
               print("verdict: delete It!")
               myDeleteResponse = requests.delete(url+apiurl+"('"+str(application["ApplicationId"])+"')",headers=headers)
               if not myDeleteResponse.ok:
                  print("error deleting")
           print("deleted")


        else:
          # If response code is not ok (200), print the resulting http error code with description
            myResponse.raise_for_status()



deleteApps()
