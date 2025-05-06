# OSPF練習
PCとルータ(frr)をdockerコンテナで作成し、ルーティング情報をOSPFで動的に作成するデモ。

## ネットワーク構成図
<img src="images/topology.png">

- 部署ごとにエリアを分ける（営業部⇒エリア1、技術部⇒エリア2）
- 中継ルータは単一障害点とならないよう冗長化
- 営業部の斜めの経路は低優先（コスト値=500を設定）

## 起動方法
```
docker compose up --build
```

## 解説
起動して数分後、OSPFで経路が広告される。<br>
例として、技術部のr21ルータでは以下のルートが作成される。
```
$ docker compose exec -it r21 /bin/sh
/ # vtysh

Hello, this is FRRouting (version 7.5_git).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

r21# show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.2.1.1, eth0, 00:01:07
C>* 2.2.2.21/32 is directly connected, lo, 00:01:07
O>* 10.0.1.0/24 [110/30] via 10.2.1.254, eth0, weight 1, 00:00:12
O>* 10.0.2.0/24 [110/20] via 10.2.1.254, eth0, weight 1, 00:00:12
O>* 10.0.3.0/24 [110/30] via 10.2.2.254, eth1, weight 1, 00:00:12
O>* 10.0.4.0/24 [110/20] via 10.2.2.254, eth1, weight 1, 00:00:12
O>* 10.0.91.0/24 [110/30] via 10.2.1.254, eth0, weight 1, 00:00:12
O>* 10.0.92.0/24 [110/30] via 10.2.2.254, eth1, weight 1, 00:00:12
O>* 10.1.1.0/24 [110/40] via 10.2.1.254, eth0, weight 1, 00:00:02
O>* 10.1.2.0/24 [110/530] via 10.2.2.254, eth1, weight 1, 00:00:12
O>* 10.1.3.0/24 [110/530] via 10.2.1.254, eth0, weight 1, 00:00:02
O>* 10.1.4.0/24 [110/40] via 10.2.2.254, eth1, weight 1, 00:00:12
O   10.2.1.0/24 [110/10] is directly connected, eth0, weight 1, 00:01:06
C>* 10.2.1.0/24 is directly connected, eth0, 00:01:07
O   10.2.2.0/24 [110/10] is directly connected, eth1, weight 1, 00:00:22
C>* 10.2.2.0/24 is directly connected, eth1, 00:01:07
O>* 192.168.11.0/24 [110/50] via 10.2.1.254, eth0, weight 1, 00:00:02
O>* 192.168.12.0/24 [110/50] via 10.2.2.254, eth1, weight 1, 00:00:12
O   192.168.21.0/24 [110/10] is directly connected, eth2, weight 1, 00:01:07
C>* 192.168.21.0/24 is directly connected, eth2, 00:01:07
```

pc12-1⇒pc21-1の通信ルートは以下である。
```
$ docker compose exec -it pc12-1 /bin/sh
/ # traceroute 192.168.21.101
traceroute to 192.168.21.101 (192.168.21.101), 30 hops max, 46 byte packets
 1  r12.ospf01_pc12 (192.168.12.254)  0.006 ms  0.003 ms  0.003 ms
 2  10.1.4.254 (10.1.4.254)  0.003 ms  0.006 ms  0.004 ms
 3  10.0.3.2 (10.0.3.2)  0.004 ms  0.004 ms  0.002 ms
 4  10.0.4.254 (10.0.4.254)  0.003 ms  0.003 ms  0.002 ms
 5  10.2.2.2 (10.2.2.2)  0.003 ms  0.003 ms  0.003 ms
 6  192.168.21.101 (192.168.21.101)  0.003 ms  0.003 ms  0.002 ms
```

経路切り替えの実験として、経路上のabr12の10.1.4.0のインタフェースをシャットダウンさせる。
```
$ docker compose exec -it abr12 /bin/sh
/ # vtysh

Hello, this is FRRouting (version 7.5_git).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

abr12# conf t
abr12(config)# interface eth2
abr12(config-if)# shutdown
abr12(config-if)# exit
```

pc12-1⇒pc21-1の通信ルートが以下に切り替わる。
<img src="images/topology2.png">
```
/ # traceroute 192.168.21.101
traceroute to 192.168.21.101 (192.168.21.101), 30 hops max, 46 byte packets
 1  r12.ospf01_pc12 (192.168.12.254)  0.007 ms  0.002 ms  0.002 ms
 2  10.1.3.254 (10.1.3.254)  0.003 ms  0.005 ms  0.001 ms
 3  10.0.1.2 (10.0.1.2)  0.002 ms  0.003 ms  0.002 ms
 4  10.0.2.254 (10.0.2.254)  0.002 ms  0.003 ms  0.002 ms
 5  10.2.1.2 (10.2.1.2)  0.002 ms  0.004 ms  0.003 ms
 6  192.168.21.101 (192.168.21.101)  0.003 ms  0.003 ms  0.002 ms
```

技術部のr21ルータのルーティングテーブルも変化する。<br>
（192.168.12.0/24宛てのルートが変わっていることを確認）
```
r21# show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.2.1.1, eth0, 00:15:15
C>* 2.2.2.21/32 is directly connected, lo, 00:15:15
O>* 10.0.1.0/24 [110/30] via 10.2.1.254, eth0, weight 1, 00:14:20
O>* 10.0.2.0/24 [110/20] via 10.2.1.254, eth0, weight 1, 00:14:20
O>* 10.0.3.0/24 [110/30] via 10.2.2.254, eth1, weight 1, 00:14:20
O>* 10.0.4.0/24 [110/20] via 10.2.2.254, eth1, weight 1, 00:14:20
O>* 10.0.91.0/24 [110/30] via 10.2.1.254, eth0, weight 1, 00:14:20
O>* 10.0.92.0/24 [110/30] via 10.2.2.254, eth1, weight 1, 00:14:20
O>* 10.1.1.0/24 [110/40] via 10.2.1.254, eth0, weight 1, 00:14:10
O>* 10.1.2.0/24 [110/530] via 10.2.2.254, eth1, weight 1, 00:14:20
O>* 10.1.3.0/24 [110/530] via 10.2.1.254, eth0, weight 1, 00:14:10
O>* 10.1.4.0/24 [110/540] via 10.2.1.254, eth0, weight 1, 00:01:16
O   10.2.1.0/24 [110/10] is directly connected, eth0, weight 1, 00:15:14
C>* 10.2.1.0/24 is directly connected, eth0, 00:15:15
O   10.2.2.0/24 [110/10] is directly connected, eth1, weight 1, 00:14:30
C>* 10.2.2.0/24 is directly connected, eth1, 00:15:15
O>* 192.168.11.0/24 [110/50] via 10.2.1.254, eth0, weight 1, 00:14:10
O>* 192.168.12.0/24 [110/540] via 10.2.1.254, eth0, weight 1, 00:01:47
O   192.168.21.0/24 [110/10] is directly connected, eth2, weight 1, 00:15:15
C>* 192.168.21.0/24 is directly connected, eth2, 00:15:15
```


