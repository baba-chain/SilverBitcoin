# SilverBitcoin Auto-Start Guide - Ubuntu 24.04

## Genel Bakış

Bu rehber, SilverBitcoin node'larınızın sunucu yeniden başlatıldığında otomatik olarak başlaması için systemd servisi kurulumunu anlatır.

## Özellikler

✅ **Otomatik Başlatma**: Sunucu reboot olduğunda tüm node'lar otomatik başlar
✅ **Hata Kurtarma**: Servis çökerse otomatik yeniden başlatır
✅ **Sağlık Kontrolü**: Opsiyonel 10 dakikalık periyodik kontrol
✅ **Systemd Entegrasyonu**: Standart Linux servis yönetimi
✅ **Log Yönetimi**: Tüm loglar systemd journal'da

## Ön Gereksinimler

### 1. Sistem Gereksinimleri
- Ubuntu 24.04 LTS
- systemd (varsayılan olarak yüklü)
- Root veya sudo erişimi

### 2. Node'lar Hazır Olmalı
```bash
# Node'ların çalıştığını test edin
./start-all-nodes.sh
./node-status.sh

# Çalışıyorsa durdurun
./stop-all-nodes.sh
```

### 3. Sistem Kontrolü
```bash
# Sistem hazır mı kontrol edin
./troubleshoot.sh
```

## Kurulum

### Adım 1: Auto-Start Klasörüne Gidin

```bash
cd auto-start
```

### Adım 2: Setup Scriptini Çalıştırın

```bash
sudo ./setup-autostart-ubuntu.sh
```

### Adım 3: Soruları Cevaplayın

Script size şunları soracak:

1. **SilverBitcoin dizini**: Otomatik tespit edilir, manuel girebilirsiniz
2. **Health check timer**: Opsiyonel, önerilir (yes/no)
3. **Şimdi başlat**: Servisi hemen başlatmak ister misiniz (yes/no)

### Örnek Kurulum

```bash
$ sudo ./setup-autostart-ubuntu.sh

╔════════════════════════════════════════════════════════════╗
║   🚀 SilverBitcoin Auto-Start Service Setup               ║
╚════════════════════════════════════════════════════════════╝

Detected user: ubuntu
Home directory: /home/ubuntu

✓ Found blockchain directory: /home/ubuntu/SilverBitcoin
✓ Required scripts found
✓ Local geth binary found

Creating systemd service...

✓ Service file created: /etc/systemd/system/silverbitcoin-nodes.service
✓ Health check script created: /home/ubuntu/SilverBitcoin/health-check.sh

Create automatic health check timer? (runs every 10 minutes) (yes/no): yes
✓ Health check timer created
✓ Health check timer enabled

Reloading systemd...
✓ Systemd reloaded

Enabling service...
✓ Service enabled

Start the service now? (yes/no): yes
Starting service...
● silverbitcoin-nodes.service - SilverBitcoin Validator Nodes
     Loaded: loaded
     Active: active (running)

╔════════════════════════════════════════════════════════════╗
║   ✅ Auto-Start Service Setup Complete!                    ║
╚════════════════════════════════════════════════════════════╝
```

## Servis Yönetimi

### Temel Komutlar

```bash
# Servisi başlat
sudo systemctl start silverbitcoin-nodes

# Servisi durdur
sudo systemctl stop silverbitcoin-nodes

# Servisi yeniden başlat
sudo systemctl restart silverbitcoin-nodes

# Servis durumunu kontrol et
sudo systemctl status silverbitcoin-nodes

# Otomatik başlatmayı devre dışı bırak
sudo systemctl disable silverbitcoin-nodes

# Otomatik başlatmayı etkinleştir
sudo systemctl enable silverbitcoin-nodes
```

### Log Görüntüleme

```bash
# Gerçek zamanlı loglar
sudo journalctl -u silverbitcoin-nodes -f

# Son 50 satır
sudo journalctl -u silverbitcoin-nodes -n 50

# Son 100 satır
sudo journalctl -u silverbitcoin-nodes -n 100

# Bugünün logları
sudo journalctl -u silverbitcoin-nodes --since today

# Son boot'tan beri
sudo journalctl -u silverbitcoin-nodes -b
```

### Health Check Timer

Eğer health check timer'ı etkinleştirdiyseniz:

```bash
# Timer durumu
sudo systemctl status silverbitcoin-healthcheck.timer

# Timer logları
sudo journalctl -u silverbitcoin-healthcheck -f

# Timer'ı durdur
sudo systemctl stop silverbitcoin-healthcheck.timer

# Timer'ı devre dışı bırak
sudo systemctl disable silverbitcoin-healthcheck.timer

# Timer'ı yeniden etkinleştir
sudo systemctl enable silverbitcoin-healthcheck.timer
sudo systemctl start silverbitcoin-healthcheck.timer
```

## Test Etme

### Test 1: Servis Durumu

```bash
sudo systemctl status silverbitcoin-nodes
```

Beklenen çıktı:
```
● silverbitcoin-nodes.service - SilverBitcoin Validator Nodes
     Loaded: loaded (/etc/systemd/system/silverbitcoin-nodes.service; enabled)
     Active: active (running) since ...
```

### Test 2: Node'lar Çalışıyor mu?

```bash
# Tmux session'larını kontrol et
tmux ls

# Node durumunu kontrol et
./node-status.sh
```

### Test 3: Reboot Testi

```bash
# Sunucuyu yeniden başlat
sudo reboot

# Yeniden bağlandıktan sonra
sudo systemctl status silverbitcoin-nodes
tmux ls
./node-status.sh
```

### Test 4: Hata Kurtarma

```bash
# Tüm node'ları manuel durdur
./stop-all-nodes.sh

# Servis otomatik yeniden başlatacak (30 saniye sonra)
sleep 35

# Kontrol et
sudo systemctl status silverbitcoin-nodes
tmux ls
```

## Servis Detayları

### Oluşturulan Dosyalar

1. **Systemd Service**: `/etc/systemd/system/silverbitcoin-nodes.service`
   - Ana servis tanımı
   - Auto-start konfigürasyonu

2. **Health Check Script**: `$BLOCKCHAIN_DIR/health-check.sh`
   - Node sayısını kontrol eder
   - 10'dan az node varsa restart eder

3. **Health Check Timer**: `/etc/systemd/system/silverbitcoin-healthcheck.timer`
   - Her 10 dakikada bir çalışır
   - Health check scriptini tetikler

4. **Health Check Service**: `/etc/systemd/system/silverbitcoin-healthcheck.service`
   - Timer tarafından çalıştırılır

### Servis Konfigürasyonu

```ini
[Unit]
Description=SilverBitcoin Validator Nodes
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/home/ubuntu/SilverBitcoin
ExecStartPre=/bin/sleep 10
ExecStart=/home/ubuntu/SilverBitcoin/start-all-nodes.sh
ExecStop=/home/ubuntu/SilverBitcoin/stop-all-nodes.sh
Restart=on-failure
RestartSec=30
TimeoutStartSec=300
TimeoutStopSec=120
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

### Önemli Parametreler

- **After=network-online.target**: Network hazır olana kadar bekler
- **ExecStartPre=/bin/sleep 10**: Başlamadan önce 10 saniye bekler
- **Restart=on-failure**: Hata durumunda yeniden başlatır
- **RestartSec=30**: Yeniden başlatma arası 30 saniye bekler
- **TimeoutStartSec=300**: Başlatma için max 5 dakika
- **LimitNOFILE=65536**: Dosya descriptor limiti
- **LimitNPROC=4096**: Process limiti

## Sorun Giderme

### Sorun 1: Servis Başlamıyor

**Kontrol:**
```bash
sudo systemctl status silverbitcoin-nodes
sudo journalctl -u silverbitcoin-nodes -n 50
```

**Olası Nedenler:**
- Geth binary bulunamıyor
- Node'lar initialize edilmemiş
- İzin sorunları
- Network hazır değil

**Çözüm:**
```bash
# Geth'i kontrol et
which geth
./geth version

# Node'ları kontrol et
ls -la nodes/

# İzinleri kontrol et
ls -la start-all-nodes.sh

# Manuel başlatmayı dene
./start-all-nodes.sh
```

### Sorun 2: Reboot Sonrası Başlamıyor

**Kontrol:**
```bash
# Servis enabled mi?
sudo systemctl is-enabled silverbitcoin-nodes

# Boot loglarını kontrol et
sudo journalctl -u silverbitcoin-nodes -b
```

**Çözüm:**
```bash
# Servisi enable et
sudo systemctl enable silverbitcoin-nodes

# Yeniden başlat
sudo systemctl start silverbitcoin-nodes
```

### Sorun 3: Bazı Node'lar Başlamıyor

**Kontrol:**
```bash
# Kaç node çalışıyor?
tmux ls | grep node | wc -l

# Node loglarını kontrol et
cat nodes/Node01/node.log
```

**Çözüm:**
```bash
# Servisi restart et
sudo systemctl restart silverbitcoin-nodes

# Veya manuel başlat
./start-all-nodes.sh
```

### Sorun 4: Health Check Çalışmıyor

**Kontrol:**
```bash
# Timer aktif mi?
sudo systemctl status silverbitcoin-healthcheck.timer

# Timer logları
sudo journalctl -u silverbitcoin-healthcheck -n 20
```

**Çözüm:**
```bash
# Timer'ı restart et
sudo systemctl restart silverbitcoin-healthcheck.timer

# Manuel health check
./health-check.sh
```

### Sorun 5: Servis "Failed" Durumunda

**Kontrol:**
```bash
sudo systemctl status silverbitcoin-nodes
sudo journalctl -u silverbitcoin-nodes -n 100
```

**Çözüm:**
```bash
# Servisi reset et
sudo systemctl reset-failed silverbitcoin-nodes

# Yeniden başlat
sudo systemctl start silverbitcoin-nodes
```

## Servisi Kaldırma

Eğer auto-start'ı kaldırmak isterseniz:

```bash
cd auto-start
sudo ./remove-autostart.sh
```

Bu işlem:
- Servisi durdurur
- Auto-start'ı devre dışı bırakır
- Servis dosyalarını siler
- Node'larınızı silmez (sadece otomatik başlatma kaldırılır)

Manuel başlatma:
```bash
./start-all-nodes.sh
```

## İleri Seviye

### Bekleme Süresini Artırma

Eğer network yavaş hazırlanıyorsa:

```bash
sudo nano /etc/systemd/system/silverbitcoin-nodes.service

# ExecStartPre satırını değiştir
ExecStartPre=/bin/sleep 30  # 10'dan 30'a çıkar

# Reload et
sudo systemctl daemon-reload
sudo systemctl restart silverbitcoin-nodes
```

### Resource Limitlerini Artırma

```bash
sudo nano /etc/systemd/system/silverbitcoin-nodes.service

# Limit satırlarını değiştir
LimitNOFILE=131072  # 65536'dan 131072'ye
LimitNPROC=8192     # 4096'dan 8192'ye

# Reload et
sudo systemctl daemon-reload
sudo systemctl restart silverbitcoin-nodes
```

### Health Check Sıklığını Değiştirme

```bash
sudo nano /etc/systemd/system/silverbitcoin-healthcheck.timer

# OnUnitActiveSec satırını değiştir
OnUnitActiveSec=5min  # 10min'den 5min'e

# Reload et
sudo systemctl daemon-reload
sudo systemctl restart silverbitcoin-healthcheck.timer
```

### Custom Start Script

Kendi başlatma scriptinizi kullanmak için:

```bash
sudo nano /etc/systemd/system/silverbitcoin-nodes.service

# ExecStart satırını değiştir
ExecStart=/path/to/your/custom-start.sh

# Reload et
sudo systemctl daemon-reload
sudo systemctl restart silverbitcoin-nodes
```

## Monitoring

### Systemd Status

```bash
# Tüm SilverBitcoin servisleri
systemctl list-units | grep silverbitcoin

# Servis durumu
systemctl status silverbitcoin-nodes

# Timer durumu
systemctl status silverbitcoin-healthcheck.timer
```

### Log Monitoring

```bash
# Gerçek zamanlı tüm loglar
sudo journalctl -u silverbitcoin-nodes -u silverbitcoin-healthcheck -f

# Son 1 saatin logları
sudo journalctl -u silverbitcoin-nodes --since "1 hour ago"

# Hata logları
sudo journalctl -u silverbitcoin-nodes -p err
```

### Node Monitoring

```bash
# Node durumu
./node-status.sh

# Tmux session'ları
tmux ls

# Belirli bir node'a bağlan
tmux attach -t node1
```

## Best Practices

1. **İlk Kurulumda Test Edin**
   - Servisi kurun
   - Manuel test edin
   - Reboot test edin

2. **Logları Takip Edin**
   - İlk günlerde logları kontrol edin
   - Hata pattern'lerini tespit edin

3. **Health Check Kullanın**
   - Otomatik kurtarma için önemli
   - 10 dakika uygun bir interval

4. **Yedek Alın**
   - Servis dosyalarını yedekleyin
   - Node key'lerini yedekleyin

5. **Dokümante Edin**
   - Özel konfigürasyonları not edin
   - Değişiklikleri kaydedin

## Özet

✅ **Kurulum**: `sudo ./setup-autostart-ubuntu.sh`
✅ **Yönetim**: `systemctl` komutları
✅ **Monitoring**: `journalctl` ve `node-status.sh`
✅ **Kaldırma**: `sudo ./remove-autostart.sh`

Auto-start servisi kurulduktan sonra node'larınız sunucu her yeniden başlatıldığında otomatik olarak çalışmaya başlayacak!
