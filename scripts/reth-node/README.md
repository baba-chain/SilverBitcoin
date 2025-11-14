# 🦀 Reth Node - Rust Ethereum Implementation

Reth, Paradigm tarafından geliştirilen yüksek performanslı Rust tabanlı Ethereum implementasyonudur.

## 3 Farklı Kurulum Yöntemi

### 1️⃣ Hızlı Kurulum (ÖNERİLEN) - 1 dakika
Pre-built binary indir ve kullan:
```bash
cd scripts/reth-node
./install-reth.sh
# Seçenek 1'i seç
```

### 2️⃣ Kaynak Koddan Build - 30-60 dakika
Tam kontrol için kaynak koddan derle:
```bash
cd scripts/reth-node
./build-from-source.sh
```

### 3️⃣ Cargo Run (Development) - Her çalıştırmada compile
Geliştirme için, her seferinde compile eder:
```bash
cd scripts/reth-node
./run-with-cargo.sh
```

## Kullanım

### Node'u Başlat
```bash
./start-reth-node.sh
```

### Durum Kontrolü
```bash
./reth-status.sh
```

### Node'u Durdur
```bash
./stop-reth-node.sh
```

### Console'a Bağlan
```bash
tmux attach -t reth-node
# Çıkmak için: Ctrl+B sonra D
```

## Port Bilgileri

- HTTP RPC: `9545`
- WebSocket: `9546`
- P2P: `30403`
- Auth RPC: `8651`

## Özellikler

- ⚡ Yüksek performans (Rust)
- 🔒 Güvenli ve modern
- 📊 Gelişmiş debugging araçları
- 🌐 Tam Ethereum uyumluluğu

## Geth ile Karşılaştırma

| Özellik | Geth (Go) | Reth (Rust) |
|---------|-----------|-------------|
| Dil | Go | Rust |
| Performans | İyi | Çok İyi |
| Bellek | Orta | Düşük |
| Sync Hızı | İyi | Çok Hızlı |
