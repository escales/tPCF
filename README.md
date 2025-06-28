grep 'App instance exited' logfile.log \
| sed -E 's/.*guid ([^ ]+).*"instance"=>"([^"]+)".*"cell_id"=>"([^"]+)".*"exit_description"=>"([^"]+)".*/\1,\2,\3,"\4"/' \
| sort \
| uniq -c \
| awk '{print $1 "," $2}' \
| sed -E 's/^ *([0-9]+) (.*)/\2,\1/'
