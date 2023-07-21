# Set variable
# PRIVATE_KEY="APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH" # APrivateKey1zkp5YNBfkaoFCB1uVkMWrSzTGcopR3Qzr3Zq445Jiq1LzKs
# VIEW_KEY="AViewKey1mSnpFFC8Mj4fXbK5YiWgZ3mjiV8CxA79bYNa8ymUpTrw" # AViewKey1idac8p5Ck1UHhzcHUAgy4CPcPqcdAoy5bAdoN2S2qcYZ
# PROGRAM_ID="aleo_dex_v2.aleo"
# API_URL="http://localhost:3030"

# Testnet 3:
PRIVATE_KEY="APrivateKey1zkp5YNBfkaoFCB1uVkMWrSzTGcopR3Qzr3Zq445Jiq1LzKs"
VIEW_KEY="AViewKey1idac8p5Ck1UHhzcHUAgy4CPcPqcdAoy5bAdoN2S2qcYZ"
PROGRAM_ID="aleo_0f87c8_v5.aleo"
API_URL="https://vm.aleo.org/api"

# Get cipher_text from tx:
TX="at15kxevpf6nhxnumkn7e97lywv9qjkvmk26lu29vuyf0hjff2fscqsg3zg3h"
CIPHER_TEXT=$(curl -s $API_URL/testnet3/transaction/$TX | jq '.fee.transition.outputs[0].value')

# Error get CIPHER_TEXT in above step --> change echo direct CIPHER_TEXT
echo $(curl -s $API_URL/testnet3/transaction/$TX | jq '.fee.transition.outputs[0].value')

# Copy CIPHER_TEXT to line below to get INPUT_RECORD
INPUT_RECORD=$(snarkos developer decrypt -v $VIEW_KEY -c $CIPHER_TEXT)
echo $(snarkos developer decrypt -v $VIEW_KEY -c $CIPHER_TEXT)

# Scan for get first Record
snarkos developer scan -v "${VIEW_KEY}" --start 0 --end 1 --endpoint "$API_URL"

# Deploy
snarkos developer deploy $PROGRAM_ID -p "${PRIVATE_KEY}" -q "$API_URL" --path "./build/" -b "$API_URL/testnet3/transaction/broadcast" --fee 600000 --record "${INPUT_RECORD}"

# Execute init_dex
snarkos developer execute $PROGRAM_ID init_dex 123456field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# Get Mapping: 
$API_URL/testnet3/program/$PROGRAM_ID/mapping/token_next_id/1u8 --> 1u64
$API_URL/testnet3/program/$PROGRAM_ID/mapping/token_name_to_owner/0field --> aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px

# Execute add_new_token 1field
snarkos developer execute $PROGRAM_ID add_new_token 1field 6u8 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# Get Mapping:
$API_URL/testnet3/program/$PROGRAM_ID/mapping/token_id_to_name/1u64 --> 1field
$API_URL/testnet3/program/$PROGRAM_ID/mapping/token_name_to_info/1field --> {\n  id: 1u64,\n  name: 1field,\n  decimals: 6u8,\n  reserves: 0u128,\n  is_liquid_token: false\n}
$API_URL/testnet3/program/$PROGRAM_ID/mapping/token_name_to_owner/1field --> aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px

# Execute add_new_token 2field
snarkos developer execute $PROGRAM_ID add_new_token 2field 6u8 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# Mint token 1field
snarkos developer execute $PROGRAM_ID mint_by_name aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2 1000000000000000u128 1field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# Get Key hash for address + token name --> không có return chạy 1 chương trình riêng
snarkos developer execute $PROGRAM_ID get_address_token_name_hash aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2 1field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# Token name 1 + address hash: 4457930901896528130261831806534342068651903095984629570319179882340345649055field
# Get amount token 1field
$API_URL/testnet3/program/$PROGRAM_ID/mapping/account_token_to_amount/4457930901896528130261831806534342068651903095984629570319179882340345649055field

# Mint token 2field
snarkos developer execute $PROGRAM_ID mint_by_name aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2 1000000000000000u128 2field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# Mint token 3field, 4field
snarkos developer execute $PROGRAM_ID mint_by_name aleo1rfrx7v3elmsd9yk4dz2h7lsmqv9lrh5pu4khuudzwmpukm0axc8sc3glsf 1000000000000000u128 3field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"
snarkos developer execute $PROGRAM_ID mint_by_name aleo1rfrx7v3elmsd9yk4dz2h7lsmqv9lrh5pu4khuudzwmpukm0axc8sc3glsf 1000000000000000u128 4field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# Token name 2 + address hash: 4933992703872097140066831415151638688641050999971214027294294755404356459968field
$API_URL/testnet3/program/$PROGRAM_ID/mapping/account_token_to_amount/4933992703872097140066831415151638688641050999971214027294294755404356459968field


# Create new pool --> Note: Lỗi set TokenInfo try_get_token --> fixed
snarkos developer execute $PROGRAM_ID create_new_pool 1field 2field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}" 
# --> Tx: at19xgf6uete7y3jlfyjvw27g2p7ghz0xva3vuwcvh2vaptk6df7v8saknur7

$API_URL/testnet3/program/$PROGRAM_ID/mapping/token_id_to_name/3u64 --> 3904538235078694782185823076632282886217961102128932463472941961302626985810field

# Add liquidity
snarkos developer execute $PROGRAM_ID add_liquidity 500000000000u128 1000000000000u128 1u64 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"
snarkos developer execute $PROGRAM_ID remove_liquidity 353553390593u128 1u64 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"


# Deploy v2 --> tx at1ttvq2h09hpv6un0q4fgkhkx3wjmn2k9xnp0w7c9u48rq2e359gqqyt9e25
#  Run square root
snarkos developer execute $PROGRAM_ID square_root 100u128 200u128 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# New account:
# Private Key  APrivateKey1zkp7LyuuXHXUKAtMQ5atfuFu3wXWyaA6qrG6ewCGdpBsHLf
# View Key  AViewKey1ePZ81teC1FigwV7ihqfRw6drFXXhKrJeSEb4UF9NvSJB
# Address  aleo13mnz5gzdxfmmsevlclh8rjyk7lptvfvdv0h5x03zjemf7lgnev9s0uf7kt

# Transfer token 1 to aleo13mnz5gzdxfmmsevlclh8rjyk7lptvfvdv0h5x03zjemf7lgnev9s0uf7kt
snarkos developer execute $PROGRAM_ID transfer_by_token_id aleo1rfrx7v3elmsd9yk4dz2h7lsmqv9lrh5pu4khuudzwmpukm0axc8sc3glsf 10000000000000u128 1u64 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"
snarkos developer execute $PROGRAM_ID transfer_by_token_id aleo1rfrx7v3elmsd9yk4dz2h7lsmqv9lrh5pu4khuudzwmpukm0axc8sc3glsf 10000000000000u128 2u64 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

# --> Last TX: at187tm40dg4ht3cmwl3k648j90g7d7qqud8knyjcah432ts6untsqq74de7l
# Hash aleo13mnz5gzdxfmmsevlclh8rjyk7lptvfvdv0h5x03zjemf7lgnev9s0uf7kt + 1field = 1961987742298488930845225791528433403552072318216646853679605614627007744684field
# Get amount of aleo13mnz5gzdxfmmsevlclh8rjyk7lptvfvdv0h5x03zjemf7lgnev9s0uf7kt
$API_URL/testnet3/program/$PROGRAM_ID/mapping/account_token_to_amount/1961987742298488930845225791528433403552072318216646853679605614627007744684field

# Swap Token1 to Token 2
snarkos developer execute $PROGRAM_ID swap 50000000000u128 1u64 1field -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"
# --> Last TX: at1fawx8xn76rfxu43lqfgwuyx2jsg569qky3puewsj73dcjzcxkyzsh06rn3

# New account:
# Private Key  APrivateKey1zkpEqk5SCPJmBMmVMDuntu3pRb6Lkt3faKCxBNf1gBHc933
# View Key  AViewKey1g8EBMbhnxchix1u6mxnhZNuabC4NKFm8bV7eRFAQGhoF
# Address  aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2
--> Last Tx: at1979jgrml6tk3al5e2pdxtf8s2gd0cx6xpkzcg5qztd7whqgfsyqq0tstwn

# Transfer credits to aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2
snarkos developer execute credits.aleo transfer_private '{owner: aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px.private,  microcredits: 93750000000000u64.private}' aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2.private 1000000000000u64.private -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

snarkos developer execute credits.aleo transfer_public aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2 -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee 10000 --record "${INPUT_RECORD}"

snarkos developer transfer-private --amount 2000000000000 --input-record "${INPUT_RECORD}" --recipient aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2  -p "${PRIVATE_KEY}" -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast" --fee-record "${INPUT_RECORD}" --fee 10000

# Mint credits
snarkos developer execute credits.aleo mint aleo1zp45yjqhndqvgzjw9h8m33t49ky3yv8xf5ghly8f69neu5lnquzqpfptm2 1000000000000u64 -p APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH -q "$API_URL" -b "$API_URL/testnet3/transaction/broadcast"

# --> TX join record: at12rerag36vund8jgh5autsucjwfx6n6n28a0z9vd5lj440srug5rqlv3arq