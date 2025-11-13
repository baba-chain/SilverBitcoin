# SilverBitcoin - Hızlı Başlangıç

## 🚀 Tek Komutla Kurulum

```bash
# Ubuntu 24.04 için
scripts/setup/setup-blockchain-complete.sh

# VEYA npm ile
npm run setup-blockchain
```

Bu komut:
1. ✅ Sistem bağımlılıklarını yükler
2. ✅ Geth'i derler
3. ✅ Node key'lerini oluşturur
4. ✅ Genesis'i günceller
5. ✅ Node'ları initialize eder
6. ✅ Tüm node'ları başlatır

## 📋 Temel Komutlar

```bash
# Node'ları başlat
scripts/node-management/start-all-nodes.sh
# veya: npm run start-nodes

# Node durumunu kontrol et
scripts/node-management/node-status.sh
# veya: npm run node-status

# Node'ları durdur
scripts/node-management/stop-all-nodes.sh
# veya: npm run stop-nodes

# Sistem kontrolü
scripts/maintenance/troubleshoot.sh
# veya: npm run troubleshoot

# Hızlı test
scripts/maintenance/quick-test.sh
# veya: npm run quick-test
```

## 📁 Klasör Yapısı

```
SilverBitcoin/
├── scripts/                    # Tüm yönetim scriptleri
│   ├── setup/                 # Kurulum scriptleri
│   ├── node-management/       # Node yönetimi
│   ├── maintenance/           # Bakım ve güncelleme
│   ├── auto-start/           # Otomatik başlatma
│   ├── deployment/           # Deployment araçları
│   └── utilities/            # Yardımcı araçlar
├── docs/                      # Dokümantasyon
│   └── setup-guides/         # Kurulum rehberleri
├── SilverBitcoin/            # Geth kaynak kodu
├── System-Contracts/         # Smart contract'lar
└── nodes/                    # Node data dizinleri
```

## 📚 Detaylı Dokümantasyon

- **Kurulum Rehberi**: [UBUNTU-SETUP.md](UBUNTU-SETUP.md)
- **Script Dokümantasyonu**: [scripts/README.md](scripts/README.md)
- **Auto-Start Kurulumu**: [scripts/auto-start/README.md](scripts/auto-start/README.md)
- **Değişiklikler**: [docs/setup-guides/UBUNTU-24.04-CHANGES.md](docs/setup-guides/UBUNTU-24.04-CHANGES.md)

## 🔧 npm Scripts

```bash
# Blockchain kurulumu
npm run setup-blockchain

# Node yönetimi
npm run start-nodes
npm run stop-nodes
npm run node-status

# Bakım
npm run troubleshoot
npm run quick-test
npm run update-deps

# Geth build
npm run build-geth

# Contract'lar
npm run compile-contracts
npm run deploy-contracts
```

## 🆘 Sorun mu Yaşıyorsunuz?

```bash
# 1. Sistem kontrolü
scripts/maintenance/troubleshoot.sh
# veya: npm run troubleshoot

# 2. Hızlı test
scripts/maintenance/quick-test.sh
# veya: npm run quick-test

# 3. Logları kontrol et
cat nodes/Node01/node.log

# 4. Detaylı rehber
cat UBUNTU-SETUP.md
```

## 🔄 Otomatik Başlatma

Sunucu reboot sonrası otomatik başlatma için:

```bash
cd scripts/auto-start
sudo ./setup-autostart-ubuntu.sh
```

## 📊 Chain Bilgileri

- **Chain ID**: 5200
- **Symbol**: SBTC
- **Consensus**: Congress (PoA)
- **Block Time**: ~1 saniye
- **Validator Count**: 24
- **Total Supply**: 50,000,000 SBTC

## 🌐 RPC Endpoint

```
http://localhost:8546
```

## 💡 İpuçları

- Root dizindeki scriptler symlink'tir, gerçek dosyalar `scripts/` klasöründedir
- Her script kendi klasöründe README içerir
- npm scripts kullanarak da çalıştırabilirsiniz
- Auto-start opsiyoneldir ama production için önerilir

## 🚦 Durum Kontrolü

```bash
# Node'lar çalışıyor mu?
scripts/node-management/node-status.sh
# veya: npm run node-status

# Tmux session'ları
tmux ls

# Belirli bir node'a bağlan
tmux attach -t node1
```

Hepsi bu kadar! 🎉
