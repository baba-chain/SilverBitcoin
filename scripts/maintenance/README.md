# Maintenance Scripts

Bakım, güncelleme ve sorun giderme scriptleri.

## Scriptler

### troubleshoot.sh ⭐
**Sistem kontrolü ve sorun giderme**

```bash
./troubleshoot.sh
```

Kontrol eder:
- İşletim sistemi bilgileri
- Go kurulumu ve versiyonu
- Geth binary varlığı
- Tmux kurulumu
- Python3 kurulumu
- Gerekli paketler
- Genesis konfigürasyonu
- Node dizinleri ve durumları
- Çalışan node'lar
- Port kullanımı
- Disk alanı

**Çıktı**: Detaylı sistem raporu ve öneriler

**Kullanım**: Sorun yaşadığınızda ilk çalıştırılacak script

---

### quick-test.sh
**Hızlı sistem uyumluluk testi**

```bash
./quick-test.sh
```

10 temel test yapar:
1. OS kontrolü (Ubuntu 24.04)
2. Go kurulumu
3. Tmux kurulumu
4. Python3 kurulumu
5. Build tools
6. Script dosyaları
7. Geth source
8. Genesis dosyası
9. Tmux fonksiyonelliği
10. Disk alanı

**Çıktı**: Pass/Fail raporu

**Kullanım**: Kurulum öncesi veya sonrası hızlı kontrol

---

### update-dependencies.sh
**Bağımlılıkları günceller**

```bash
./update-dependencies.sh
```

Kontrol eder ve günceller:
- Go modülleri (Geth)
- npm paketleri (System Contracts)
- Güvenlik açıkları

İnteraktif mod:
- Hangi güncellemelerin yapılacağını sorar
- Major version güncellemeleri için uyarır
- Güvenlik düzeltmeleri önerir

**Kullanım**: Periyodik güncelleme için

---

### clean-build.sh
**Build dosyalarını temizler**

```bash
./clean-build.sh
```

Temizler:
- Geth binary
- Go build cache
- Node modules
- Geçici dosyalar

**Kullanım**: Temiz bir build için

---

## Kullanım Örnekleri

### Sistem Sorun Giderme
```bash
# Detaylı sistem kontrolü
./troubleshoot.sh

# Hızlı test
./quick-test.sh
```

### Bağımlılık Yönetimi
```bash
# Güncellemeleri kontrol et
./update-dependencies.sh

# Sadece kontrol et, güncelleme yapma
# (script içinde "no" seçeneklerini seçin)
```

### Temizlik
```bash
# Build dosyalarını temizle
./clean-build.sh

# Yeniden derle
cd ../../SilverBitcoin/node_src
go build -o geth ./cmd/geth
```

## Sorun Giderme Senaryoları

### Senaryo 1: Node'lar Başlamıyor

```bash
# 1. Sistem kontrolü
./troubleshoot.sh

# 2. Yaygın sorunları kontrol et
# - Geth binary var mı?
# - Node'lar initialize edilmiş mi?
# - Tmux kurulu mu?

# 3. Logları kontrol et
cat ../../nodes/Node01/node.log
```

### Senaryo 2: Performans Sorunları

```bash
# 1. Sistem kaynaklarını kontrol et
./troubleshoot.sh

# 2. Disk alanını kontrol et
df -h

# 3. Bellek kullanımını kontrol et
free -h

# 4. Çalışan process'leri kontrol et
ps aux | grep geth
```

### Senaryo 3: Güncelleme Sonrası Sorunlar

```bash
# 1. Build'i temizle
./clean-build.sh

# 2. Yeniden derle
cd ../../SilverBitcoin/node_src
go mod download
go mod tidy
go build -o geth ./cmd/geth
mv geth ../../

# 3. Node'ları yeniden initialize et
cd ../../scripts/setup
./initialize-nodes.sh

# 4. Başlat
cd ../node-management
./start-all-nodes.sh
```

### Senaryo 4: Bağımlılık Çakışmaları

```bash
# 1. Güncellemeleri kontrol et
./update-dependencies.sh

# 2. Go modüllerini temizle
cd ../../SilverBitcoin/node_src
go clean -modcache
go mod download
go mod tidy

# 3. npm paketlerini temizle
cd ../../System-Contracts
rm -rf node_modules package-lock.json
npm install
```

## Periyodik Bakım

### Günlük
```bash
# Node durumunu kontrol et
cd ../node-management
./node-status.sh
```

### Haftalık
```bash
# Sistem kontrolü
./troubleshoot.sh

# Log dosyalarını kontrol et
tail -100 ../../nodes/Node01/node.log
```

### Aylık
```bash
# Bağımlılıkları kontrol et
./update-dependencies.sh

# Güvenlik güncellemelerini kontrol et
cd ../../System-Contracts
npm audit
```

### Yıllık
```bash
# Major version güncellemeleri
./update-dependencies.sh
# (Major version güncellemelerini kabul et)

# Yeniden derle ve test et
./clean-build.sh
cd ../setup
./setup-blockchain-complete.sh
```

## Monitoring

### Sistem Sağlığı
```bash
# Otomatik monitoring (her 5 saniye)
watch -n 5 ./troubleshoot.sh

# Veya sadece node durumu
watch -n 5 ../node-management/node-status.sh
```

### Log Monitoring
```bash
# Gerçek zamanlı log izleme
tail -f ../../nodes/Node01/node.log

# Tüm node logları
for i in {1..24}; do
    echo "=== Node$(printf "%02d" $i) ==="
    tail -5 ../../nodes/Node$(printf "%02d" $i)/node.log
done
```

## Notlar

💡 **İpuçları**:
- `troubleshoot.sh` sorun yaşadığınızda ilk çalıştırılmalı
- `quick-test.sh` kurulum öncesi/sonrası hızlı kontrol için ideal
- Bağımlılık güncellemelerini test ortamında deneyin
- Major version güncellemeleri breaking changes içerebilir

⚠️ **Dikkat**:
- `clean-build.sh` tüm build dosyalarını siler
- Güncelleme öncesi yedek alın
- Production'da güncellemeleri dikkatli yapın

📋 **Best Practices**:
- Düzenli sistem kontrolü yapın
- Logları takip edin
- Güvenlik güncellemelerini hemen uygulayın
- Major güncellemeleri test edin
