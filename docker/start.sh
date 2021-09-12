#!/bin/bash
function RUN_APP() {
    echo /opt/apps/$2/files/run.sh
    docker exec -ti $1 /usr/bin/nohup /bin/bash /opt/apps/$2/files/run.sh &>/dev/null &
}
function USAGE() {

    echo 'Usage:'
    echo '		-i  [Docker Container ID or Name] [APP Name]'
    echo '		<APP Name> list:'
    echo ' 			      QQ'
    echo ' 			      TIM'
    echo ' 			      WeChat'
    echo ' 			      BaiduNetDisk'
    echo '			      ThunderSpeed'
    echo '			      Foxmail'
    echo 'Example: source start.sh -i 0af TIM'
}
APP_LIST=(
    com.qq.im.deepin
    com.qq.office.deepin
    com.qq.music.deepin
    WeChat
    BaiduNetDisk
    ThunderSpeed
    Foxmail
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
