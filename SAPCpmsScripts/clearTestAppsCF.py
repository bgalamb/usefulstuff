import requests
from requests.auth import HTTPDigestAuth
import json

# Replace with the correct URL

#baseurls =  ["https://service-cockpit-web-int.cfapps.sap.hana.ondemand.com/cockpit/v1/org/mobiledev_sdkforios/space/integration/app"]#,
#baseurls  = ["https://service-cockpit-web-development.cfapps.sap.hana.ondemand.com/cockpit/v1/org/mobiledev_mobile-ops-subscriber/space/development-qa/app"]#,


apiurl = "s"

headers = {"Authorization":"Basic UDE5NDI2ODQzNjE6SzZaTGllISE=","X-CSRF-Token":"fetch"}
headersdelete = {"Authorization":"Basic UDE5NDI2ODQzNjE6SzZaTGllISE="}


def deleteApps():
    for url in baseurls:
        myResponse = requests.get(url+apiurl,headers=headers)
        jsonResponse = myResponse.json()
        print (jsonResponse)

        # For successful API call, response code will be 200 (OK)
        if(myResponse.ok):
         print(type(jsonResponse))
         for application in jsonResponse:
           print("---------------------------------")
           print("Checking app...")
           print("name= "+application["name"])
           print("displayName= "+application["displayName"])
           if "delete" not in str(application["name"]) and (str(application["name"]).startswith("com.sap.") or str(application["name"]).startswith("com.afariaeng.")):
               print("verdict: leave it!")
               continue
           else:
               print("verdict: delete It!")

               #call details api
               myAppDetailsResponse = requests.get(url+"/"+str(application["name"]),headers=headers)
               csrftoken=myAppDetailsResponse.headers.get("X-CSRF-Token","None")
               cookies  =myAppDetailsResponse.cookies
               print("csrftoken= {}".format(csrftoken))

               #add csrf token to the request
               headersdelete["X-CSRF-Token"] = csrftoken

               #call delete api
               myAppDetailsResponse = requests.delete(url+"/"+str(application["name"]),headers=headersdelete,cookies=cookies)
               if not myAppDetailsResponse.ok:
                  print("error deleting")
           print("deleted")


        else:
          # If response code is not ok (200), print the resulting http error code with description
            myResponse.raise_for_status()



deleteApps()
