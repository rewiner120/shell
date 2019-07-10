#! /bin/sh
# This shell use for install mysql server.
# Pleace change the parameter for yours.such as install path  user and so on
# version 1.0
# add by Li Jianjun @ meilele.com
# time 2017-07-24

#defined the parameters
version=$1
user_name="mysql"
download_path="/opt/soft/"
source_path="/opt/soft/mysql"
#自动安装最新版本使用的参数
mirror_163_base_url="http://mirrors.163.com/mysql/Downloads/MySQL-"
mirror_sohu_base_url="http://mirrors.sohu.com/mysql/MySQL-"
install_path="/usr/local/mysql"
#特殊安装参数定义
special_download_url5="http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.60.tar.gz"     #5.5版本下载地址
special_download_url6="http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.39.tar.gz"     #5.6版本下载地址
special_download_url7="http://mirrors.sohu.com/mysql/MySQL-5.7/mysql-5.7.17.tar.gz"     #5.7版本下载地址
special_install_path="/usr/local/mysql"     #特殊安装的 安装目录
sepcial_data_path="/data/tmp/"        #特殊安装的 data目录,此处必须为空目录，请勿使用有数据存在的目录


function check_user()
{
    id mysql >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "创建用户   ${user_name}，请稍后。。。。"
        useradd ${user_name} -s /sbin/nologin -M
        if [ $? -eq 0 ];then
            echo "创建用户   ${user_name}   成功"
        else
            echo "创建用户失败！"
            exit 1
        fi
    else
        exist_mysql=1
    fi
}
function check_path()
{
    if [ ! -d ${download_path} -o ! -d ${source_path} ];then
        echo -e "download_path Or source_path dosen't exists!\nCreating needs path......\n"
        mkdir -p ${download_path} ${source_path}
        if [ $? -ne 0 ];then
	    echo "创建下载目录失败"
	    exit 1
        fi
    else
        rm -fr ${source_path}/*
    fi
}

function check_special_path()
{
    if [ ! -d ${sepcial_data_path} ];then
        echo -e "sepcial_data_path dosen't exists!\nCreating needs path......\n"
        mkdir -p ${sepcial_data_path}
        if [ $? -ne 0 ];then
	    echo "创建下载目录失败"
	    exit 1
        fi
    else
        rm -fr ${sepcial_data_path}/*
    fi
}

function check_wget_command()
{
    which wget >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "< wget > command dosen't exits.\n Begin install < wget > command.\n"
        yum install wget -y
        if [ $? -ne 0 ];then
            echo "< wget > command install failure.Please reinstall it by yourself.\n"
        else
            echo "Install wget success.....\nMySQL install continuing......\n"
        fi
    fi
        
}

function download()
{       local download_url=$1
        cd ${download_path}
        rm mysql.tar.gz -f
        wget -O mysql.tar.gz ${download_url} --no-check-certificate
        if [ $? -ne 0 ];then
            echo "下载安装包，失败！请检查网络和重新设置下载地址！"
            exit 1
        else
            tar -zxvf mysql.tar.gz -C ${source_path} --strip-components=1
        fi
}    

function install()
{
    if [$# -gt 1];then
        local install_version=$1
        local install_path_version=$2
        local final_install_path=$install_path$install_path_version
        local final_data_path=$install_path$install_path_version/data
    elif [$# -eq 1];then
        local install_version=$1
        #local install_path_version=$2
        local final_install_path=$special_install_path
        local final_data_path=$sepcial_data_path
    fi
    cd ${source_path}
    echo "安装相关依赖包.......\n" 
    sleep 3
    #yum install zlib libxml libjpeg freetype libpng gd curl libiconv zlib-devel libxml2-devel libjpeg-devel freetype-devel libpng-devel gd-devel curl-devel curl libxml2 libxml2-devel libmcrypt libmcrypt-devel libxslt* ncurses-devel openssl openssl-devel pcre pcre-devel gcc gcc-c++ dtrace systemtap-sdt-devel make cmake -y
    yum install ncurses-devel gcc gcc-c++ dtrace make cmake -y
    echo "预编译.......\n" 
	sleep 3
	cd ${source_path}
    if [[ ${install_version} != '5.7' ]];then
        cmake -DCMAKE_INSTALL_PREFIX=${final_install_path} -DMYSQL_DATADIR=${final_data_path} -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DMYSQL_UNIX_ADDR=${final_data_path}/mysql.sock -DMYSQL_TCP_PORT=3306 -DENABLED_LOCAL_INFILE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci        
        if [ $? -eq 0 ];then
            make && make install
            cd ${final_install_path}
            chown ${user_name}.${user_name} ${final_data_path} -R
            echo "数据库初始化，请稍后......."
            sleep 3
            ${final_install_path}/scripts/mysql_install_db --user=${user_name} --basedir=${final_install_path} --datadir=${final_data_path}
            if [ $? -eq 0 ];then
                echo "数据库初始化成功......."
                if [ ${exist_mysql} -eq 0 ];then
                    unalias cp
                    cp -f support-files/mysql.server /etc/init.d/mysqld
                    chown ${user_name}.${user_name} ${final_data_path} -R
                    echo "数据库启动测试....."
                    /etc/init.d/mysqld start
                    netstat -lntup |grep mysql|wc -l
                    if [ $? -eq 0 ];then
                        echo "数据库安装成功,启动命令：/etc/init.d/mysqld start"
                        echo "停止测试数据库"
                        /etc/init.d/mysqld stop
                        echo "Congratulation!MySQL Installed Successed!"
                    else
                        echo "数据库启动测试失败。。。。"
                        exit 1
                    fi
                else
                    echo "机器存在数据库，请手动启动"
                fi
            else
                echo "数据库初始化失败！请查看错误日志！"
                exit 1
            fi
        else
            echo "预编译失败！请查看错误日志！"
        fi
    else
        cmake -DCMAKE_INSTALL_PREFIX=${final_install_path} -DMYSQL_DATADIR=${final_data_path} -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DMYSQL_UNIX_ADDR=${final_data_path}/mysql.sock -DMYSQL_TCP_PORT=3306 -DENABLED_LOCAL_INFILE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/boost -DDOWNLOAD_BOOST_TIMEOUT=28800    
        if [ $? -eq 0 ];then
            make && make install
            cd ${final_install_path}
            chown ${user_name}.${user_name} ${final_data_path} -R
            echo "数据库初始化，请稍后......."
            sleep 3
            ${final_install_path}/bin/mysqld --initialize --user='mysql'
            if [ $? -eq 0 ];then
                echo "数据库初始化成功......."
                if [ ${exist_mysql} -eq 0 ];then
                    unalias cp
                    cp -f support-files/mysql.server /etc/init.d/mysqld
                    chown ${user_name}.${user_name} ${final_data_path} -R
                    echo "数据库启动测试....."
                    /etc/init.d/mysqld start
                    netstat -lntup |grep mysql|wc -l
                    if [ $? -eq 0 ];then
                        echo "数据库安装成功,启动命令：/etc/init.d/mysqld start"
                        echo "停止测试数据库"
                        /etc/init.d/mysqld stop
                        echo "Congratulation!MySQL Installed Successed!Initialize Password is:\n"
                        echo ""
                    else
                        echo "数据库启动测试失败。。。。"
                        exit 1
                    fi
                else
                    echo "机器安装过MySQL,请手动启动"
                fi
            else
                echo "数据库初始化失败！请查看错误日志！"
                exit 1
            fi
        else
            echo "预编译失败！请查看错误日志！"
        fi
    fi
}
#特殊安装函数
function special_install()
{
    check_user
    check_path
    check_special_path
    check_wget_command
    if [[ $1 == '5.5' ]];then
        download ${special_download_url5}
    elif [[ $1 == '5.6' ]];then
        download ${special_download_url6}
    elif [[ $1 == '5.7' ]];then
        download ${special_download_url7}
    else
        echo "请输入正确的版本号,目前只支持  5.5,5.6,5.7\n"
    fi
    install $1
    echo "PATH=$PATH:${install_path}/bin" >>/etc/profile
    source /etc/profile

}

#Open Source Mirrors Menu
function mirrors_menu ()
{
    local version=$1
cat << EOF
`echo -e "\n\n\n"`
`echo -e "\033[33m Please choice mirrors(请选择需要使用的开源镜像)：\033[0m"`
`echo -e "  \033[35m 1. 163 Open Source\033[0m"`
`echo -e "  \033[35m 2. Sohu Open Source\033[0m"`
`echo -e "  \033[35m 3. 返回上层菜单\033[0m"`
`echo -e "  \033[35m 4. 退出安装\033[0m"`
EOF
read -p "请输入版本号对应的数字：" mirrors_num
case $mirrors_num in
    1)
        local mirrors_url=${mirror_163_base_url}${version}/
        tmp_txt=/tmp/`date +%s`.txt
        curl ${mirrors_url} >${tmp_txt} 2>&1
        local down_url=`grep "mysql-[0-9\.]*.tar.gz\"" ${tmp_txt}|sort -nr |awk -F "\"" 'NR==2{print $2}'`
        local final_version=`grep "mysql-[0-9\.]*.tar.gz\"" ${tmp_txt}|sort -nr |awk -F "\"" '{print $2}'|awk -F "mysql-|.tar.gz" 'NR==2{print $2}'`
        local final_down_url=${mirrors_url}$down_url
        rm -f ${tmp_txt}
        echo -e "\033[33m 即将安装MySQL_${final_version}......\033[0m"
        sleep 3
        download ${final_down_url}
        install $version ${final_version}
      ;;
    2)
      local mirrors_url=${mirror_sohu_base_url}${version}/
        tmp_txt=/tmp/`date +%s`.txt
        curl ${mirrors_url} >${tmp_txt} 2>&1
        local down_url=`grep "mysql-[0-9\.]*.tar.gz\"" ${tmp_txt}|sort -nr |awk -F "href=\"|\"" 'NR==2{print $4}'`
        local final_version=`grep "mysql-[0-9\.]*.tar.gz\"" ${tmp_txt}|sort -nr |awk -F "href=\"|\"" 'NR==2{print $4}'|awk -F "mysql-|.tar.gz" '{print $2}'`
        local final_down_url=${mirrors_url}$down_url
        rm -f ${tmp_txt}
        echo -e "\033[33m 即将安装MySQL_${final_version}......\033[0m"
        sleep 3
        download ${final_down_url}
        install $version ${final_version}
      ;;
    3)
      clear
      menu
      ;;
    4)
      exit 0
esac
}



function menu ()
{
    cat << EOF
`echo -e "\033[32m |------------------------------------------------------------------|\033[0m"`
`echo -e "\033[32m |                                                                  |\033[0m"`
`echo -e "\033[32m |***************Thanks for using MySQL Install Shell***************|\033[0m"`
`echo -e "\033[32m |                                                                  |\033[0m"`
`echo -e "\033[32m |We support installation methods:                                  |\033[0m"`
`echo -e "\033[32m |    1:163 Open Source Mirror.(http://mirrors.163.com)             |\033[0m"`
`echo -e "\033[32m |    2:Sohu Open Source Mirror.(http://mirrors.sohu.com)           |\033[0m"`
`echo -e "\033[32m |                                                                  |\033[0m"`
`echo -e "\033[32m |We support three Primary Verions:                                 |\033[0m"`
`echo -e "\033[32m |    1:MySQL_5.5                                                   |\033[0m"`
`echo -e "\033[32m |    2:MySQL_5.6                                                   |\033[0m"`
`echo -e "\033[32m |    3:MySQL_5.7                                                   |\033[0m"`
`echo -e "\033[32m |                                                                  |\033[0m"`
`echo -e "\033[32m |************************Important Reminder************************|\033[0m"`
`echo -e "\033[32m |                                                                  |\033[0m"`
`echo -e "\033[32m |We don't promise the mirrors url always is valid.If it's not valid|\033[0m"`
`echo -e "\033[32m |you can edit the shell and change it.                             |\033[0m"`
`echo -e "\033[32m |                                                                  |\033[0m"`
`echo -e "\033[32m |------------------------------------------------------------------|\033[0m"`
`echo -e "\n\n\n"`
`echo -e "\033[33m Please choice primary version(主要版本号)：\033[0m"`
`echo -e "  \033[32m 1. 自动安装:MySQL_5.5\033[0m"`
`echo -e "  \033[32m 2. 自动安装:MySQL_5.6\033[0m"`
`echo -e "  \033[32m 3. 自动安装:MySQL_5.7\033[0m"`
`echo -e "  \033[35m 4. 特殊安装:MySQL_5.5(选择特殊安装必须修改脚本的special_*的参数)\033[0m"`
`echo -e "  \033[35m 5. 特殊安装:MySQL_5.6(选择特殊安装必须修改脚本的special_*的参数)\033[0m"`
`echo -e "  \033[35m 6. 特殊安装:MySQL_5.7(选择特殊安装必须修改脚本的special_*的参数)\033[0m"`
`echo -e "  \033[36m 8. 退出安装程序\033[0m"`
EOF
read -p "请输入版本号对应的数字：" num1
case $num1 in
    1)
      mirrors_menu 5.5
      #eleproduct_menu
      ;;
    2)
      mirrors_menu 5.6
      ;;
    3)
      mirrors_menu 5.7
      ;;
    4)
      special_install 5.5
      #eleproduct_menu
      ;;
    5)
      special_install 5.6
      ;;
    6)
      special_install 5.7
      ;;
    8)
      exit 0
      ;;
    *)
       menu
       ;;
esac
}




