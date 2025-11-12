# 🚀 SilverBitcoin Blockchain - Debian/Ubuntu Kurulum

## 📋 Tek Komut Kurulum

Yeni bir Debian/Ubuntu sunucuda **sıfırdan** blockchain kurmak için:

```bash
# 1. Script'i indir
wget https://raw.githubusercontent.com/YOUR_USERNAME/SilverBitcoin/main/debian-quick-setup.sh

# 2. Çalıştırılabilir yap
chmod +x debian-quick-setup.sh

# 3. Root olarak çalıştır
sudo ./debian-quick-setup.sh
```

## ✨ Ne Yapar?

Script otomatik olarak:

1. ✅ Sistem paketlerini günceller
2. ✅ Go 1.21.5 kurar
3. ✅ Node.js 20.x kurar
4. ✅ GitHub'dan projeyi klonlar
5. ✅ Geth binary'sini build eder
6. ✅ 25 validator node oluşturur
7. ✅ Genesis block'u initialize eder
8. ✅ Tüm node'ları başlatır
9. ✅ Firewall ayarlarını yapar
10. ✅ Systemd service kurar (otomatik başlatma)

## 🎯 Kurulum Sonrası

### Node'ları Kontrol Et
```bash
cd ~/SilverBitcoin
./node-status.sh
```

### Tmux Session'larını Gör
```bash
tmux ls
```

### Bir Node'a Bağlan
```bash
tmux attach -t node1
# Çıkmak için: Ctrl+B sonra D
```

### Node'ları Durdur
```bash
./stop-all-nodes.sh
```

### Node'ları Başlat
```bash
./start-all-nodes.sh
```

### Systemd ile Yönet
```bash
# Başlat
sudo systemctl start silverbitcoin

# Durdur
sudo systemctl stop silverbitcoin

# Durum
sudo systemctl status silverbitcoin

# Otomatik başlatmayı kapat
sudo systemctl disable silverbitcoin
```

## 🌐 RPC Endpoints

Kurulum sonrası RPC endpoint'ler:

- Node01: `http://SUNUCU_IP:8546`
- Node02: `http://SUNUCU_IP:8547`
- Node03: `http://SUNUCU_IP:8548`
- ... (Node24'e kadar)

## 🔥 Firewall Portları

Script otomatik olarak açar:

- **22/tcp** - SSH
- **30304-30328/tcp** - P2P (TCP)
- **30304-30328/udp** - P2P (UDP)
- **8546-8569/tcp** - RPC (opsiyonel, manuel açılmalı)

### RPC Portlarını Açmak İçin:
```bash
sudo ufw allow 8546:8569/tcp
```

## 📝 Gereksinimler

- **OS**: Debian 11/12 veya Ubuntu 20.04/22.04/24.04
- **RAM**: Minimum 4GB (8GB önerilen)
- **Disk**: Minimum 50GB SSD
- **CPU**: 2+ cores
- **Network**: Statik IP önerilen

## 🔧 Manuel Kurulum

Eğer `debian-quick-setup.sh` kullanmak istemezseniz:

```bash
# 1. Projeyi klonla
git clone https://github.com/YOUR_USERNAME/SilverBitcoin.git
cd SilverBitcoin

# 2. Blockchain'i kur
./setup-blockchain-complete.sh
```

## ⚠️ Önemli Notlar

1. **Root Gerekli**: Script `sudo` ile çalıştırılmalı
2. **GitHub URL**: Script içindeki `YOUR_USERNAME` değiştirilmeli
3. **Private Keys**: `nodes/` klasörü private key'ler içerir - GİZLİ TUT!
4. **Backup**: Kurulum sonrası `nodes/` klasörünü yedekle

## 🆘 Sorun Giderme

### Go bulunamıyor
```bash
export PATH=$PATH:/usr/local/go/bin
source ~/.bashrc
```

### Node başlamıyor
```bash
# Log'ları kontrol et
tmux attach -t node1

# Genesis'i yeniden initialize et
./geth --datadir nodes/Node01 init SilverBitcoin/genesis.json
```

### Port zaten kullanımda
```bash
# Çalışan process'leri kontrol et
sudo lsof -i :8546
sudo lsof -i :30304

# Gerekirse kill et
sudo kill -9 <PID>
```

## 📚 Daha Fazla Bilgi

- [Complete Deployment Guide](COMPLETE-DEPLOYMENT-GUIDE.md)
- [Node Management](NODE-MANAGEMENT.md)
- [Security Guide](SECURITY-PRIVATE-KEYS.md)

## 🎉 Başarılı Kurulum

Kurulum başarılı olduğunda göreceksiniz:

```
╔════════════════════════════════════════════════════════════╗
║   ✅ Setup Complete!                                       ║
╚════════════════════════════════════════════════════════════╝

🚀 Ready to start blockchain!
```

Blockchain çalışıyor! 🎊
