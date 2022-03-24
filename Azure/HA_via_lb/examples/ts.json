{
  "class": "Telemetry",
  "My_System": {
      "class": "Telemetry_System",
      "systemPoller": {
          "interval": 60
      }
  },
  "My_Listener": {
      "class": "Telemetry_Listener",
      "port": 6514
  },
  "My_Consumer": {
    "class": "Telemetry_Consumer",
    "type": "Azure_Log_Analytics",
    "workspaceId": "${law_id}",
    "passphrase": {
        "cipherText": "${law_primkey}"
    },
    "useManagedIdentity": false,
    "region": "${region}"
  }
}
