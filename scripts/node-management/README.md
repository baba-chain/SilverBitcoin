# Node Management Scripts

Node başlatma, durdurma ve yönetim scriptleri.

## Scriptler

### start-all-nodes.sh ⭐
**Tüm validator node'larını başlatır** (Node01-Node24)

```bash
./start-all-nodes.sh
```

- 24 validator node'u başlatır (Node25 treasury, başlatılmaz)
- Her node için tmux session oluşturur
- Zaten çalışan node'ları atlar
- Başlatma sonrası doğrulama yapar

**Çıktı**: Başlatılan, zaten çalışan ve başarısız node sayıları

---

### start-node.sh
**Tek bir node'u başlatır**

```bash
./start-node.sh <node_number>

# Örnek
./start-node.sh 1   # Node01'i başlatır
./start-node.sh 15  # Node15'i başlatır
```

- Belirtilen node'u başlatır
- Genesis initialize kontrolü yapar
- Account import kontrolü yapar
- Tmux session oluşturur
- Log dosyası oluşturur

**Kullanım**: Tek bir node'u başlatmak veya restart etmek için

---

### stop-all-nodes.sh
**Tüm node'ları durdurur**

```bash
./stop-all-nodes.sh
```

- Tüm tmux session'larını kapatır (Node01-Node25)
- Güvenli durdurma (0.5s delay)
- Durdurma sonrası doğrulama yapar

**Çıktı**: Durdurulan ve zaten durmuş node sayıları

---

### stop-node.sh
**Tek bir node'u durdurur**

```bash
./stop-node.sh <node_number>

# Örnek
./stop-node.sh 1   # Node01'i durdurur
```

**Kullanım**: Tek bir node'u durdurmak için

---

### node-status.sh ⭐
**Tüm node'ların durumunu gösterir**

```bash
./node-status.sh
```

Gösterir:
- Her node'un durumu (RUNNING/STOPPED)
- Port dinleme durumu
- HTTP, WebSocket, P2P portları
- Toplam çalışan/durmuş node sayısı
- Blockchain block numarası

**Kullanım**: Node'ların sağlığını kontrol etmek için

---

## Kullanım Örnekleri

### Tüm Node'ları Başlat
```bash
./start-all-nodes.sh
```

### Durumu Kontrol Et
```bash
./node-status.sh
```

### Belirli Bir Node'a Bağlan
```bash
tmux attach -t node1
# Çıkmak için: Ctrl+B sonra D
```

### Tüm Node'ları Durdur
```bash
./stop-all-nodes.sh
```

### Tek Bir Node'u Restart Et
```bash
./stop-node.sh 5
./start-node.sh 5
```

### Tmux Session'larını Listele
```bash
tmux ls
```

## Node Portları

Her node farklı portlarda çalışır:

| Node | HTTP RPC | WebSocket | P2P |
|------|----------|-----------|-----|
| Node01 | 8546 | 8547 | 30304 |
| Node02 | 8547 | 8548 | 30305 |
| Node03 | 8548 | 8549 | 30306 |
| ... | ... | ... | ... |
| Node24 | 8569 | 8570 | 30327 |

## Tmux Komutları

```bash
# Tüm session'ları listele
tmux ls

# Bir node'a bağlan
tmux attach -t node1

# Session'dan çık (node çalışmaya devam eder)
Ctrl+B sonra D

# Session'ı kapat (node'u durdurur)
Ctrl+D veya exit
```

## Log Dosyaları

Her node için log dosyası:
```bash
# Log dosyasını görüntüle
cat nodes/Node01/node.log

# Gerçek zamanlı log izle
tail -f nodes/Node01/node.log
```

## Sorun Giderme

### Node Başlamıyor
```bash
# Log kontrol et
cat nodes/Node01/node.log

# Tmux session'a bağlan
tmux attach -t node1

# Manuel başlatmayı dene
./start-node.sh 1
```

### Port Çakışması
```bash
# Kullanılan portları kontrol et
ss -tuln | grep 8546

# Process'i bul
sudo lsof -i :8546

# Durdur
sudo kill -9 <PID>
```

### Tmux Session Kalmış
```bash
# Tüm node session'larını temizle
for i in {1..25}; do tmux kill-session -t node$i 2>/dev/null; done

# Veya tüm tmux session'larını temizle
tmux kill-server
```

## Notlar

💡 **İpuçları**:
- `node-status.sh` ile düzenli kontrol yapın
- Node loglarını takip edin
- Tmux'tan çıkarken Ctrl+D değil Ctrl+B D kullanın (node çalışmaya devam eder)

⚠️ **Dikkat**:
- Node25 (Treasury) otomatik başlatılmaz
- Her node için yeterli RAM olduğundan emin olun
- Port çakışmalarına dikkat edin
