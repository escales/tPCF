Try querying historical logs or audit events:
cf curl "/v3/audit_events?target_guid=<APP-GUID>"
cf curl "/v3/audit_events?target_guid=<APP-GUID>"

grep 'App instance exited' logfile.log | awk -F'guid | payload: ' '{print $2, $3}' | sed -E 's/\{.*"instance"=>"([^"]+)",.*"cell_id"=>"([^"]+)",.*"exit_description"=>"([^"]+?)",.*/\1,\2,\3/' | awk -v OFS=',' '{print guid=$1, instance=$2, cell_id=$3, exit_description=substr($0, index($0,$4))}'

grep 'App instance exited' logfile.log | sed -E 's/.*guid ([^ ]+).*"instance"=>"([^"]+)".*"cell_id"=>"([^"]+)".*"exit_description"=>"([^"]+)".*/\1,\2,\3,"\4"/'






