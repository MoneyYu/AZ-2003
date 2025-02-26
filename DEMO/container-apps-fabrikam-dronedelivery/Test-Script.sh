export INGESTION_FQDN=ingestion-app.blackground-0f47061c.eastus2.azurecontainerapps.io



curl -X POST "https://${INGESTION_FQDN}/api/deliveryrequests" --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
   "confirmationRequired": "None",
   "deadline": "",
   "dropOffLocation": "drop off",
   "expedited": true,
   "ownerId": "myowner",
   "packageInfo": {
     "packageId": "mypackage",
     "size": "Small",
     "tag": "mytag",
     "weight": 10
   },
   "pickupLocation": "mypickup",
   "pickupTime": "'$(date -u +%FT%TZ)'"
 }'




export AI_ID=5aa03830-3b30-4d39-937f-a88ceec2c741

 az monitor app-insights query --app $AI_ID --analytics-query 'requests
| summarize count_=sum(itemCount) by operation_Name
| order by operation_Name
| project strcat(operation_Name," (", count_, ")")' --query tables[0].rows[] -o table



{"deliveryId":"b9a06995-c8a1-4da2-a3dd-3911890edd7e","ownerId":"myowner","pickupLocation":"mypickup","pickupTime":"2025-02-26T03:56:40.000+0000","deadline":"","expedited":true,"confirmationRequired":"None","packageInfo":{"packageId":"mypackage","size":"Small","weight":10.0,"tag":"mytag"},"dropOffLocation":"drop off"}