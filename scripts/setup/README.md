# Setup Scripts

İlk kurulum ve yapılandırma scriptleri.

## Scriptler

### setup-blockchain-complete.sh ⭐
**Tam otomatik kurulum** - Tek komutla her şeyi yapar

```bash
./setup-blockchain-complete.sh
```

Bu script:
1. Sistem bağımlılıklarını kontrol eder ve yükler
2. Geth binary'sini derler
3. Validator private key'lerini oluşturur
4. Genesis.json'u günceller
5. Tüm node'ları initialize eder
6. Node'ları başlatır

**Kullanım**: İlk kurulum için ideal

---

### generate-node-keys.sh
**Node key'lerini oluşturur**

```bash
./generate-node-keys.sh
```

- 25 validator için private key oluşturur
- Genesis.json'u otomatik günceller
- Her node için 2,000,000 SBTC tahsis eder
- Mevcut key'leri yedekler

**Kullanım**: Yeni key'ler oluşturmak için

---

### initialize-nodes.sh
**Node'ları genesis ile initialize eder**

```bash
./initialize-nodes.sh
```

- Genesis block'u her node için oluşturur
- Chaindata dizinlerini hazırlar
- Initialize durumunu kontrol eder

**Kullanım**: Key'ler oluşturulduktan sonra

---

### setup-nodes.sh
**Node dizinlerini oluşturur** (güvenli versiyon)

```bash
./setup-nodes.sh
```

- Sadece dizin yapısını oluşturur
- Key'leri sunucuda oluşturmanız için placeholder bırakır
- Güvenlik için önerilir

**Kullanım**: Manuel key yönetimi için

---

## Kurulum Sırası

### Hızlı Kurulum (Önerilen)
```bash
# Tek komut
./setup-blockchain-complete.sh
```

### Manuel Kurulum
```bash
# 1. Node key'lerini oluştur
./generate-node-keys.sh

# 2. Node'ları initialize et
./initialize-nodes.sh

# 3. Node'ları başlat
cd ../node-management
./start-all-nodes.sh
```

## Gereksinimler

- Ubuntu 24.04 LTS
- Go 1.21+ (otomatik yüklenir)
- Git, build-essential, tmux
- Python3
- Root/sudo erişimi

## Notlar

⚠️ **Güvenlik**: 
- `generate-node-keys.sh` private key'ler oluşturur
- Bu key'leri asla GitHub'a commit etmeyin
- Production'da güçlü şifreler kullanın

💡 **İpucu**:
- İlk kurulum için `setup-blockchain-complete.sh` kullanın
- Manuel kontrol istiyorsanız adım adım scriptleri kullanın
