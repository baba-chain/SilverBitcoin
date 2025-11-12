# 📦 NPM Scripts Guide

SilverBitcoin blockchain için kullanılabilir npm komutları.

## 🚀 Hızlı Başlangıç

### Yeni Sunucu (Debian/Ubuntu)
```bash
npm run setup-debian
```
Tüm bağımlılıkları kurar ve blockchain'i başlatır.

### Hazır Sunucu
```bash
npm run setup-blockchain
```
Sadece blockchain'i kurar ve başlatır.

---

## 📋 Tüm Komutlar

### 🔧 Kurulum Komutları

#### `npm run setup-debian`
Debian/Ubuntu sunucuda sıfırdan kurulum (root gerekli)
- Sistem paketlerini günceller
- Go 1.21.5 kurar
- Node.js 20.x kurar
- GitHub'dan projeyi klonlar
- Blockchain'i kurar ve başlatır

```bash
sudo npm run setup-debian
```

#### `npm run setup-blockchain`
Blockchain'i kurar (Go ve Node.js zaten yüklü olmalı)
- Geth build eder
- 25 validator node oluşturur
- Genesis initialize eder
- Node'ları başlatır

```bash
npm run setup-blockchain
```

#### `npm run setup`
System-Contracts için npm paketlerini kurar

```bash
npm run setup
```

---

### 🏗️ Build Komutları

#### `npm run build-geth`
Geth binary'sini build eder

```bash
npm run build-geth
```

Output: `SilverBitcoin/geth`

---

### 🔑 Node Yönetimi

#### `npm run generate-keys`
25 validator için private key'ler üretir ve genesis.json'u günceller

```bash
npm run generate-keys
```

#### `npm run init-nodes`
Tüm node'lar için genesis block'u initialize eder

```bash
npm run init-nodes
```

#### `npm run start-nodes`
Tüm validator node'larını başlatır (Node01-Node24)

```bash
npm run start-nodes
```

#### `npm run stop-nodes`
Tüm çalışan node'ları durdurur

```bash
npm run stop-nodes
```

#### `npm run node-status`
Node'ların durumunu gösterir

```bash
npm run node-status
```

---

### 📜 Smart Contract Komutları

#### `npm run compile-contracts`
System-Contracts'ı derler

```bash
npm run compile-contracts
```

#### `npm run deploy-contracts`
Contract'ları blockchain'e deploy eder

```bash
npm run deploy-contracts
```

---

### ✅ Test ve Doğrulama

#### `npm start` veya `npm run verify`
Mainnet doğrulama scriptini çalıştırır

```bash
npm start
# veya
npm run verify
```

#### `npm test`
Test suite'i çalıştırır

```bash
npm test
```

---

## 🎯 Kullanım Senaryoları

### Senaryo 1: İlk Kurulum (Yeni Sunucu)

```bash
# 1. Projeyi klonla
git clone https://github.com/YOUR_USERNAME/SilverBitcoin.git
cd SilverBitcoin

# 2. Debian quick setup (her şeyi kurar)
sudo npm run setup-debian

# 3. Durum kontrol
npm run node-status
```

### Senaryo 2: İlk Kurulum (Hazır Sunucu)

```bash
# 1. Projeyi klonla
git clone https://github.com/YOUR_USERNAME/SilverBitcoin.git
cd SilverBitcoin

# 2. Blockchain setup
npm run setup-blockchain

# 3. Durum kontrol
npm run node-status
```

### Senaryo 3: Manuel Kurulum

```bash
# 1. Geth build et
npm run build-geth

# 2. Key'leri üret
npm run generate-keys

# 3. Genesis initialize
npm run init-nodes

# 4. Node'ları başlat
npm run start-nodes

# 5. Durum kontrol
npm run node-status
```

### Senaryo 4: Node'ları Yeniden Başlat

```bash
# Durdur
npm run stop-nodes

# Başlat
npm run start-nodes

# Kontrol
npm run node-status
```

### Senaryo 5: Contract Deploy

```bash
# 1. Contract'ları derle
npm run compile-contracts

# 2. Deploy et
npm run deploy-contracts
```

---

## 🔍 Komut Detayları

### setup-blockchain
**Çalıştırır:** `./setup-blockchain-complete.sh`

**Yapar:**
1. Geth build
2. Key generation
3. Genesis update
4. Node initialization
5. Node startup

**Gereksinimler:**
- Go 1.21+
- Node.js 20+
- tmux

### start-nodes
**Çalıştırır:** `./start-all-nodes.sh`

**Yapar:**
- Node01-Node24 başlatır (tmux sessions)
- Node25 (Treasury) atlanır

**Kontrol:**
```bash
tmux ls
```

### stop-nodes
**Çalıştırır:** `./stop-all-nodes.sh`

**Yapar:**
- Tüm tmux session'larını kapatır
- Node process'lerini temiz şekilde durdurur

### node-status
**Çalıştırır:** `./node-status.sh`

**Gösterir:**
- Çalışan node sayısı
- Tmux session'ları
- RPC endpoint'ler
- Faydalı komutlar

---

## 🛠️ Troubleshooting

### "Permission denied" hatası
```bash
chmod +x *.sh
```

### "Go not found" hatası
```bash
# Go'yu kur
sudo npm run setup-debian
```

### "Port already in use" hatası
```bash
# Node'ları durdur
npm run stop-nodes

# Tekrar başlat
npm run start-nodes
```

### Script çalışmıyor
```bash
# Executable yap
chmod +x setup-blockchain-complete.sh
chmod +x generate-node-keys.sh
chmod +x initialize-nodes.sh
chmod +x start-all-nodes.sh
chmod +x stop-all-nodes.sh
chmod +x node-status.sh
```

---

## 📚 İlgili Dökümanlar

- [Debian Setup README](DEBIAN-SETUP-README.md)
- [Complete Deployment Guide](COMPLETE-DEPLOYMENT-GUIDE.md)
- [Node Management](NODE-MANAGEMENT.md)
- [Security Guide](SECURITY-PRIVATE-KEYS.md)

---

## 💡 İpuçları

1. **İlk kurulum için:** `npm run setup-debian` kullan
2. **Hızlı test için:** `npm run setup-blockchain` kullan
3. **Production için:** Manuel kurulum yap
4. **Durum kontrolü:** `npm run node-status` sık sık çalıştır
5. **Backup:** `nodes/` klasörünü düzenli yedekle

---

## 🎉 Başarılı Kurulum

Kurulum başarılı olduğunda:

```bash
npm run node-status
```

Çıktı:
```
✅ 24 nodes running
✅ RPC: http://YOUR_IP:8546
✅ Chain ID: 5200
```

Blockchain çalışıyor! 🚀
