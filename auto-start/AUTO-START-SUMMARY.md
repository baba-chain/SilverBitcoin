# SilverBitcoin Auto-Start - Özet

## Ne Yapar?

Sunucu yeniden başlatıldığında (reboot) tüm SilverBitcoin node'larınız otomatik olarak başlar. Müdahale etmenize gerek kalmaz.

## Hızlı Kurulum

```bash
cd auto-start
sudo ./setup-autostart-ubuntu.sh
```

## Özellikler

✅ **Otomatik Başlatma**: Reboot sonrası node'lar otomatik başlar
✅ **Hata Kurtarma**: Servis çökerse otomatik yeniden başlatır
✅ **Health Check**: Her 10 dakikada node'ları kontrol eder (opsiyonel)
✅ **Systemd Entegrasyonu**: Standart Linux servis yönetimi
✅ **Log Yönetimi**: Tüm loglar systemd journal'da

## Temel Komutlar

```bash
# Servisi başlat
sudo systemctl start silverbitcoin-nodes

# Servisi durdur
sudo systemctl stop silverbitcoin-nodes

# Durum kontrol
sudo systemctl status silverbitcoin-nodes

# Logları görüntüle
sudo journalctl -u silverbitcoin-nodes -f

# Servisi kaldır
cd auto-start && sudo ./remove-autostart.sh
```

## Nasıl Çalışır?

1. **Systemd Service**: `/etc/systemd/system/silverbitcoin-nodes.service`
   - Sunucu boot olduğunda otomatik çalışır
   - Network hazır olana kadar bekler (10 saniye)
   - `start-all-nodes.sh` scriptini çalıştırır

2. **Health Check Timer**: Her 10 dakikada bir (opsiyonel)
   - Node sayısını kontrol eder
   - 10'dan az node varsa servisi restart eder

3. **Auto Recovery**: Servis çökerse
   - 30 saniye bekler
   - Otomatik yeniden başlatır

## Test Etme

### 1. Servis Durumu
```bash
sudo systemctl status silverbitcoin-nodes
```

### 2. Node'lar Çalışıyor mu?
```bash
tmux ls
./node-status.sh
```

### 3. Reboot Testi
```bash
sudo reboot
# Yeniden bağlandıktan sonra
sudo systemctl status silverbitcoin-nodes
```

## Sorun Giderme

### Servis Başlamıyor
```bash
# Logları kontrol et
sudo journalctl -u silverbitcoin-nodes -n 50

# Manuel başlatmayı dene
./start-all-nodes.sh
```

### Reboot Sonrası Başlamıyor
```bash
# Servis enabled mi?
sudo systemctl is-enabled silverbitcoin-nodes

# Enable et
sudo systemctl enable silverbitcoin-nodes
```

## Dosyalar

### Yeni (Ubuntu 24.04)
- `setup-autostart-ubuntu.sh` - Kurulum scripti
- `remove-autostart.sh` - Kaldırma scripti
- `UBUNTU-AUTOSTART-GUIDE.md` - Detaylı rehber
- `README.md` - Genel bilgi

### Eski (Deprecated)
- `create-autostart-service.sh` - Eski kurulum
- `AUTO_START_SERVICE_GUIDE.md` - Eski rehber

## Gereksinimler

- Ubuntu 24.04 LTS
- systemd (varsayılan)
- Root/sudo erişimi
- Node'lar initialize edilmiş ve çalışıyor

## Opsiyonel mi?

**Evet!** Auto-start opsiyoneldir. Node'larınız auto-start olmadan da çalışır, sadece reboot sonrası manuel başlatmanız gerekir:

```bash
./start-all-nodes.sh
```

## Avantajları

1. **Zaman Tasarrufu**: Reboot sonrası manuel başlatmaya gerek yok
2. **Güvenilirlik**: Elektrik kesintisi sonrası otomatik devreye girer
3. **Monitoring**: Health check ile sürekli kontrol
4. **Profesyonel**: Production ortamlar için standart

## Dezavantajları

1. **Karmaşıklık**: Bir systemd servisi daha
2. **Debug**: Sorun olursa systemd loglarına bakmak gerekir
3. **Root Gereksinimi**: Kurulum için sudo gerekli

## Öneri

**Production sunucular için şiddetle önerilir!**
**Development/test ortamlar için opsiyonel.**

## Detaylı Dokümantasyon

- **Kurulum Rehberi**: `UBUNTU-AUTOSTART-GUIDE.md`
- **Genel Bilgi**: `README.md`
- **Ana Rehber**: `../UBUNTU-SETUP.md`

## Hızlı Başlangıç

```bash
# 1. Node'ların çalıştığını test et
./start-all-nodes.sh
./node-status.sh
./stop-all-nodes.sh

# 2. Auto-start kur
cd auto-start
sudo ./setup-autostart-ubuntu.sh

# 3. Test et
sudo systemctl status silverbitcoin-nodes

# 4. Reboot test et
sudo reboot
```

Hepsi bu kadar! 🚀
