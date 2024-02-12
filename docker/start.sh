#!/bin/bash
function RUN_APP() {
    docker exec -ti $1 /usr/bin/nohup /bin/bash /opt/apps/$2/files/run.sh &>/dev/null &
}
function USAGE() {

    echo 'Usage:'
    echo '		-i  [Docker Container ID or Name] [APP Name]'
    echo '		<APP Name> list:'
    echo ' 			      com.qq.im.deepin'
    echo ' 			      com.evernote.deepin'
    echo 'Example: source start.sh -i 0af com.qq.im.deepin'
}
APP_LIST=(
    com.qq.im.deepin
    com.qq.office.deepin
    com.qq.music.deepin
    com.qq.weixin.deepin
    com.evernote.deepin
    com.taobao.wangwang.deepin
)
if [ $# != 3 ]; then
    USAGE
else
    case ${1} in
    -i)
        shift ##ID
        if { docker ps -a |& grep $1; } &>/dev/null; then
            ID=$1
            shift ##APP
            { for i in ${APP_LIST[@]}; do echo $i; done |& grep -i "^${1}$"; } 2>/dev/null 1>APP && RUN_APP ${ID} $(cat APP) ||
                echo "Sorry,'$1' not in list"
        else
            echo "ERROR: Docker Container ID \"$1\" doesn't exist."
            return 2
        fi
        ;;
    *)
        USAGE
        ;;
    esac
fi
[ -f APP ] && shred -f -u -z APP >/dev/null 2>&1
