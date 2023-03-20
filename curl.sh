#set -x
#set -e 

user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 Edg/111.0.1661.44"
header1="accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
header2="accept-encoding: gzip, deflate, br"

connect_timeout=5
max_time=30
max_filesize=50000000

declare -a -g headers
declare -g body
declare -g time_total
declare -g remote_ip
declare -g http_code
declare -g url_effective
declare -a body_add
declare -a response

request(){
raw_response=$(curl -A "${user_agent}" -H "${header1}" -H "${header2}" --connect-timeout "${connect_timeout:-5}" -m "${max_time}" --max-filesize "${max_filesize}" --compressed --no-keepalive  -sSLkf  -D - --url "$url" -w '\n%{url_effective}\n%{http_code}\n%{remote_ip}\n%{time_total}' 2>&1 )
number_headers_section=$(while read -r line;do if [[ $line = $'\r' ]];then echo return;fi;done <<< "${raw_response}" | wc -l)
head=true
count=0
while read -r line; do 
    if $head; then
        if [[ $line = $'\r' ]];then count=$(( $count + 1 ));fi
        if [[ $line = $'\r' ]] && [[ $number_headers_section -eq $count ]]; then
            head=false
        else
            headers="$headers"$'\n'"$line"
        fi
    else
        body="$body"$'\n'"$line"
    fi
done <<<"$raw_response"

read time_total remote_ip http_code url_effective str1 < <(echo "${body}" | tac | tr '\n' ' ' )
 
if [ -z "${http_code}" ]
then
    echo "Error: $raw_response" | head -n1
    exit 0
else
    declare -a body_add
    unset str1

    while read -r; do body_add+=("$REPLY");done <<<"$body"
    for count in {1..4};do unset "body_add[${#body_add[@]}-1]";done
    body=$( "${body_add[*]}" )
    
    echo "status: ${http_code:-no_code}"
    echo "remote ip: ${remote_ip:-no_ip}"
    echo "real url: ${url_effective:-no_url}"
    echo "time: ${time_total:-no_time}"
    server=$(echo "${headers[@]}" | grep server |tail -n1)
    echo "${server:-no_server}"
    echo "lenght body: $(echo ${body_add[*]} | wc -c)"
fi
}

if [ -z "$1" ];then echo "run $0 url";else request "$1";fi

