#!/bin/bash

# Ethereum/SilverBitcoin Adres Üretici
# Basit ve hızlı adres üretimi

echo "=================================="
echo "SilverBitcoin Adres Üretici"
echo "=================================="
echo ""

# Python3.9'u kullan (eth-account kurulu olan versiyon)
/usr/bin/python3.9 -c "
from eth_account import Account
import secrets

print('🔐 Yeni Ethereum/SilverBitcoin Adresleri Oluşturuluyor...\n')

# Premine Adresi
print('=' * 50)
print('📦 PREMINE ADRESİ (50,000,000 SBTC)')
print('=' * 50)
priv1 = secrets.token_hex(32)
private_key1 = '0x' + priv1
acct1 = Account.from_key(private_key1)
print(f'Address: {acct1.address}')
print(f'Private Key: {private_key1}')
print('')

# Validator Adresi
print('=' * 50)
print('⚡ VALIDATOR ADRESİ (Genesis Validator)')
print('=' * 50)
priv2 = secrets.token_hex(32)
private_key2 = '0x' + priv2
acct2 = Account.from_key(private_key2)
print(f'Address: {acct2.address}')
print(f'Private Key: {private_key2}')
print('')

print('=' * 50)
print('⚠️  ÖNEMLİ UYARILAR:')
print('=' * 50)
print('1. Private key\'leri GÜVENLİ bir yere kaydedin!')
print('2. Private key\'leri KİMSEYLE paylaşmayın!')
print('3. Bu adresler tüm EVM ağlarında çalışır')
print('4. Aynı private key = Aynı adres (tüm ağlarda)')
print('')
print('✅ Genesis.json\'da kullanabilirsiniz!')
print('=' * 50)
"
