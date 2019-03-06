#! /bin/sh
# This shell use for install mysql server.
# Pleace change the parameter for yours.such as install path  user and so on
# version 1.0
# add by Li Jianjun @ meilele.com
# time 2017-07-24

#defined the parameters
install_path="/usr/local/mysql$1"
version=$1
user_name="mysql"
download_url5="http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.60.tar.gz"
download_url6="http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.39.tar.gz"
download_url7="http://mirrors.sohu.com/mysql/MySQL-5.7/mysql-5.7.17.tar.gz"
download_path="/opt/soft/"
source_path="/opt/soft/mysql"

function check_user()
{
    id mysql
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

function check_wget_command()
{
    which wget
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
cd ${source_path}
    echo "安装相关依赖包.......\n" 
    sleep 3
    #yum install zlib libxml libjpeg freetype libpng gd curl libiconv zlib-devel libxml2-devel libjpeg-devel freetype-devel libpng-devel gd-devel curl-devel curl libxml2 libxml2-devel libmcrypt libmcrypt-devel libxslt* ncurses-devel openssl openssl-devel pcre pcre-devel gcc gcc-c++ dtrace systemtap-sdt-devel make cmake -y
    yum install ncurses-devel gcc gcc-c++ dtrace make cmake -y
    echo "预编译.......\n" 
	sleep 3
	cd ${source_path}
    if [[ ${version} != '5.7' ]];then
        cmake -DCMAKE_INSTALL_PREFIX=${install_path} -DMYSQL_DATADIR=${install_path}/data -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DMYSQL_UNIX_ADDR=${install_path}/data/mysql.sock -DMYSQL_TCP_PORT=3306 -DENABLED_LOCAL_INFILE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci        
        if [ $? -eq 0 ];then
            make && make install
            cd ${install_path}
            chown ${user_name}.${user_name} ${install_path}/data -R
            echo "数据库初始化，请稍后......."
            sleep 3
            ${install_path}/scripts/mysql_install_db --user=${user_name} --basedir=${install_path} --datadir=${install_path}/data
            if [ $? -eq 0 ];then
                echo "数据库初始化成功......."
                if [ ${exist_mysql} -eq 0 ];then
                    unalias cp
                    cp -f support-files/mysql.server /etc/init.d/mysqld
                    chown ${user_name}.${user_name} ${install_path}/data -R
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
        cmake -DCMAKE_INSTALL_PREFIX=${install_path} -DMYSQL_DATADIR=${install_path}/data -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DMYSQL_UNIX_ADDR=${install_path}/data/mysql.sock -DMYSQL_TCP_PORT=3306 -DENABLED_LOCAL_INFILE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/boost -DDOWNLOAD_BOOST_TIMEOUT=28800    
        if [ $? -eq 0 ];then
            make && make install
            cd ${install_path}
            chown ${user_name}.${user_name} ${install_path}/data -R
            echo "数据库初始化，请稍后......."
            sleep 3
            ${install_path}/bin/mysqld --initialize --user='mysql'
            if [ $? -eq 0 ];then
                echo "数据库初始化成功......."
                if [ ${exist_mysql} -eq 0 ];then
                    unalias cp
                    cp -f support-files/mysql.server /etc/init.d/mysqld
                    chown ${user_name}.${user_name} ${install_path}/data -R
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
if [[ $# != 1 ]];then
    echo "Usage: mysql_install.sh 版本号"
    echo "eg: mysql_install.sh 5.6"
else
    check_user
    check_path
    check_wget_command
    if [[ $1 == '5.5' ]];then
        download ${download_url5}
    elif [[ $1 == '5.6' ]];then
        download ${download_url6}
    elif [[ $1 == '5.7' ]];then
        download ${download_url7}
    else
        echo "请输入正确的版本号,目前只支持  5.5,5.6,5.7\n"
    fi
    install
    echo "PATH=$PATH:${install_path}/bin" >>/etc/profile
    source /etc/profile
fi



