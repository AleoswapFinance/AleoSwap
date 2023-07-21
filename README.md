# Aleo_DEX

This is the first DEX on the ALEO blockchain. This program contains 2 subprogram: `token` and `dex`, which are aggregated into `main.leo`.

## Mapping explaination

The program only have mapping types which is stored in the chain. There are a few things to know about the mappings:

* token_next_id (u8 → u64): this mapping just be created for storing 2 values: number of all kind of tokens (can get by query 0u8 value) and number of liquidity tokens(can get by query 1u8 value).

The token_id of new token is the value of current number of all kind of tokens.

The pool_id of new pool  is the value of current number of liquidity tokens, which means each pool will have one liquidity token represent for it.

* token_id_to_name (u64 → field): mapping from token_id to token_name.

The token_name is the hashed value of token_name, which has type `field`, not the real value of it. (Liquidity token's token_name has value which is the hash of pool_id using BHP256::hash_to_field function)

* token_name_to_info (field → TokenInfo):  mapping from token_name to TokenInfo.

This is what inside TokenInfo struct:

```rust
struct TokenInfo {
    // token id
    id: u64,
    // token name
    name: field,
    // decimals
    decimals: u8,
    // token reserves
    reserves: u128,
    // token is liquidity token or not
    is_liquid_token: bool,
}
```

* token_name_to_owner(u64 → address): Each token can only have one owner of its own. The owner can mint token whenever they want. But only normal token(not the liquidity one) can use mint function.

* account_token_to_amount (Pair → u128): Pair contains the account address and the token id. So the mapping represent the amount of the account in each type of token.

```rust
struct Pair {
    addr: address,
    token_name: field,
}
```

* pool_id_to_pool (u64 → PoolInfo): when we create a pool, we also create a liquidity token along with it. Each pool has a pair of token and a pool_id(different from token_id)

```rust
struct PoolInfo {
    token1_name: field,
    token2_name: field,
    reserve1: u128,
    reserve2: u128,
    // total supply of liquidity token
    total_supply: u128,
}
```

### Before getting into the subprogram, the program needs to be executed the init_dex() function. This function will set some initial values to the mapping so that the subprogram can work successfully.

## Token subprogram

The token subprogram is a set of the functions which support create, mint and transfer token. Create and mint only work with normal one(not liquidity token).

* add_new_token: this function is used for create a new token. the caller is the owner of the token, who can mint the token. Due to mappings take value from token_name, each token can't have the same name.

* mint_by_name: this function will add a given amount to the given receiver. But only token_owner can call it. And also, the token need to be existed first.

* mint_by_id: same as mint_by_name but as the token_name is some value which is hashed, this function is create to help user not to remember the token name.

* transfer_by_name: send an amount from caller to receiver. If the caller don't have enough balance, the function will fail. (Only normal token)

* transfer_by_token_id: same as transfer_by_name but work with both kind of token.

* transfer_liquid_token:  same as transfer_by_name but only work with liquidity token.

## DEX subprogram

The DEX subprogram is a set of the functions which support create and swap pool, add and remove liquidity on pool.

As the program does not have address, amount of all token which should be sent to to the program now is sent to the DEX owner. Currently, DEX owner is the one who call init_dex function. But this will be update in the future so the DEX owner is some kind of 0 address.

Liquidity pools in Aleo Dex are autonomous and use the Constant Product Market Maker (x * y = k) as Uniswap does.

* create_new_pool: this function is used for create a new liquidity pool. The caller define the pair of token for pool.

* add_liquidity: The caller will transfer 2 tokens in pool to the DEX owner and receive an amount of liquidity token corresponding to their amount.

* remove_liquidity: with a give amount of liquidity token, the caller now can burn the token to receive 2 tokens in pool. This will be update more in the future so they can also receive incentive while holding liquidity token.

* swap: swap an amount of one token in pool and get another token.
