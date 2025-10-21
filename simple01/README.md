# 練習環境の構築 その１

## 概要
１台のUbuntu環境上で、Dockerを使ってネットワークの練習環境を構築します。<br>
あらかじめDockerがインストールされている前提とします。<br>
最初はDockerコンテナで作成した２台のPC間でping確認を行い、徐々に練習環境を拡張していきます。

### 動作環境
- PC: Appleシリコン搭載のMacbook上のVM
- OS: Ubuntu22.04.5 LTS
- Docker: version 27.5.1
<br>
## 資材のダウンロードと環境設定
任意のディレクトリ上でgit cloneします。

```Shell
git clone https://github.com/koyamaru3/network-train.git
```

今回使用する資材へ移動します。
```Shell
cd network-train/simple01
```

環境設定ファイルを編集します。
```
vi .env
```

TRANS_NICにPCのネットワークインタフェース名を設定します。<br>
インタフェース名は ip addrコマンドで確認できます。<br>
（通常はloインタフェースの次に表示されるインタフェースが該当。ここでは例としてenp0s5を設定します。）
```INI
TRAIN_NIC=enp0s5
```

## ネットワーク構成
下図の通り、Dockerコンテナで作成した2台のPCを同一の仮想ネットワーク上で接続します。<br>
<br>
<img src="images/topology.png">

## 動作確認
解説は後回しにして、先にpingの動作確認を行ってみます。<br>
<br>
以下を実行し、PCを一斉起動させます。
```Shell
docker compose up --build
```

別のターミナルを開き、pc1のコンテナに入ってpingを実行します。
```Shell
docker exec -it pc1 /bin/sh
```

pc2宛てにpingを実行すると応答が返ってきます。
```Shell
/ # ping 10.1.1.102
PING 10.1.1.102 (10.1.1.102): 56 data bytes
64 bytes from 10.1.1.102: seq=0 ttl=64 time=0.388 ms
64 bytes from 10.1.1.102: seq=1 ttl=64 time=0.170 ms
64 bytes from 10.1.1.102: seq=2 ttl=64 time=0.112 ms
```

終了する際は、コンテナを起動したターミナルをCtrl+Cし、以下を実行して後片付けします。
```
docker compose down
```

## 解説

```YML
services:
  pc1:
    build: ./pc1
    container_name: pc1
    hostname: pc1
    tty: true
    stdin_open: true
    privileged: true
    networks:
      vlan1:
        ipv4_address: 10.1.1.101
  pc2:
    build: ./pc2
    container_name: pc2
    hostname: pc2
    tty: true
    stdin_open: true
    privileged: true
    networks:
      vlan1:
        ipv4_address: 10.1.1.102

networks:
  vlan1:
    driver: macvlan
    driver_opts:
      parent: ${TRAIN_NIC}.1
    ipam:
      config:
        - subnet: 10.1.1.0/24
          gateway: 10.1.1.254
```

```Shell
$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:1c:42:97:2b:40 brd ff:ff:ff:ff:ff:ff
    inet 10.211.55.6/24 metric 100 brd 10.211.55.255 scope global dynamic enp0s5
       valid_lft 1377sec preferred_lft 1377sec
    inet6 fdb2:2c26:f4e4:0:21c:42ff:fe97:2b40/64 scope global dynamic mngtmpaddr noprefixroute 
       valid_lft 2591682sec preferred_lft 604482sec
    inet6 fe80::21c:42ff:fe97:2b40/64 scope link 
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:d6:3a:8d:52 brd ff:ff:ff:ff:ff:ff
8: br-5f195c875120: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:c8:8b:5d:f7 brd ff:ff:ff:ff:ff:ff
11: br-ebd648b5fa24: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:02:fc:33:c3 brd ff:ff:ff:ff:ff:ff
13: br-171dfefd0e3f: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:44:9e:ff:e1 brd ff:ff:ff:ff:ff:ff
2400: enp0s5.1@enp0s5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 00:1c:42:97:2b:40 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::21c:42ff:fe97:2b40/64 scope link 
       valid_lft forever preferred_lft forever
```


```Shell
parallels@ubuntu02:~$ sudo tcpdump -i enp0s5 -nn
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s5, link-type EN10MB (Ethernet), snapshot length 262144 bytes
```

```Shell
$ sudo tcpdump -i enp0s5.1 -nn
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on enp0s5.1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
23:35:05.095951 IP 10.1.1.101 > 10.1.1.102: ICMP echo request, id 22, seq 0, length 64
23:35:05.096027 IP 10.1.1.102 > 10.1.1.101: ICMP echo reply, id 22, seq 0, length 64
23:35:06.097768 IP 10.1.1.101 > 10.1.1.102: ICMP echo request, id 22, seq 1, length 64
23:35:06.097782 IP 10.1.1.102 > 10.1.1.101: ICMP echo reply, id 22, seq 1, length 64
23:35:07.098328 IP 10.1.1.101 > 10.1.1.102: ICMP echo request, id 22, seq 2, length 64
23:35:07.098360 IP 10.1.1.102 > 10.1.1.101: ICMP echo reply, id 22, seq 2, length 64
```

