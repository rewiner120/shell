#! /bin/sh
# This shell use for install mysql server.
# Pleace change the parameter for yours.such as install path  user and so on
# version 1.0
# add by Li Jianjun @ meilele.com
# time 2017-07-24

#defined the parameters
install_path="/data/mysql"
user_name="mysql"
#source_path="${download_path}/5.5.31"
#depend_packages=""
download_url="https://downloads.mysql.com/archives/get/file/mysql-5.5.31.tar.gz"
download_path="/data/"
source_path="${download_path}/mysql-5.5.31"

if [ ! -d ${download_path} ];then
    echo "download_path dosen't exists,please change it"
    exit 1
else
    cd ${download_path}
#    wget -O mysql.tar.gz ${download_url} --no-check-certificate
    if [ $? -ne 0 ];then
        echo "下载安装包，失败！请检查网络和重新设置下载地址！"
        exit 1
    else
        tar -zxf mysql.tar.gz
    fi    
fi

cd ${source_path}

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
    echo "安装相关依赖包......." 
    yum install zlib libxml libjpeg freetype libpng gd curl libiconv zlib-devel libxml2-devel libjpeg-devel freetype-devel libpng-devel gd-devel curl-devel curl libxml2 libxml2-devel libmcrypt libmcrypt-devel libxslt* ncurses-devel openssl openssl-devel pcre pcre-devel gcc gcc-c++ dtrace systemtap-sdt-devel make cmake -y
    
    echo "预编译......." 
	sleep 3
	cd ${source_path}
    cmake -DCMAKE_INSTALL_PREFIX=${install_path} -DMYSQL_DATADIR=${install_path}/data -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DMYSQL_TCP_PORT=3306 -DENABLED_LOCAL_INFILE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci
    if [ $? -eq 0 ];then
        make && make install
        cd ${install_path}
		chown ${user_name}.${user_name} ${install_path}/data -R
        echo "数据库初始化，请稍后......."
		sleep 3
        ${install_path}/scripts/mysql_install_db --user=${user_name} --basedir=${install_path} --datadir=${install_path}/data
        if [ $? -eq 0 ];then
            echo "数据库初始化成功......."
            cp support-files/mysql.server /etc/init.d/mysqld
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
            echo "数据库初始化失败！请查看错误日志！"
            exit 1
        fi
    else
        echo "预编译失败！请查看错误日志！"
    fi
fi    





