# township

TownShip

## 使用说明
    git clone https://github.com/aasdpiao/skynet-simulator.git
    cd skynet-simulator
    make

    mysql 依赖
    yum install mysql mysql-server mysql-devel
    service mysql start

    mysql -uroot

    CREATE USER township@localhost IDENTIFIED BY '123456';
    GRANT ALL ON *.* TO township@localhost;
    flush privileges; 

    redis 依赖
    ./tools/start_redis.sh

    ./run.sh

    127.0.0.1:8003?username=zdq&password=123456    通过http协议注册账号

    ./client.sh   

    ./stop.sh

## 缺少依赖
    autoconf        yum install autoconf (centos)

    readline-devel  yum install readline-devel

    gcc             yum install gcc

    make            yum install make

## gcc升级
    $ sudo yum install centos-release-scl
    $ sudo yum install devtoolset-7
    $ scl enable devtoolset-7 bash