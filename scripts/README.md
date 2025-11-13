# SilverBitcoin Scripts

Bu klasör tüm yönetim scriptlerini içerir.

## Klasör Yapısı

### 📁 setup/
İlk kurulum ve yapılandırma scriptleri
- Blockchain kurulumu
- Node key oluşturma
- Genesis initialize
- Sistem bağımlılıkları

### 📁 node-management/
Node başlatma, durdurma ve yönetim scriptleri
- Node başlatma/durdurma
- Tüm node'ları yönetme
- Node durumu kontrolü

### 📁 maintenance/
Bakım ve güncelleme scriptleri
- Bağımlılık güncellemeleri
- Sistem kontrolü
- Sorun giderme
- Temizlik işlemleri

### 📁 auto-start/
Otomatik başlatma servisleri
- Systemd servis kurulumu
- Health check
- Servis yönetimi

### 📁 deployment/
Deployment ve release scriptleri
- GitHub hazırlığı
- Release oluşturma
- Deployment araçları

### 📁 utilities/
Yardımcı araçlar
- Adres oluşturma
- Test scriptleri
- Geliştirici araçları

## Hızlı Erişim

### İlk Kurulum
```bash
scripts/setup/setup-blockchain-complete.sh
```

### Node Yönetimi
```bash
scripts/node-management/start-all-nodes.sh
scripts/node-management/stop-all-nodes.sh
scripts/node-management/node-status.sh
```

### Sistem Kontrolü
```bash
scripts/maintenance/troubleshoot.sh
scripts/maintenance/quick-test.sh
```

### Auto-Start Kurulumu
```bash
cd scripts/auto-start
sudo ./setup-autostart-ubuntu.sh
```

## Eski Scriptler

Root dizindeki scriptler geriye dönük uyumluluk için korunmuştur.
Yeni kurulumlar için `scripts/` klasörünü kullanın.
