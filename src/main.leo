// The 'aleo_dex' program.
program aleo_0f87c8_v5.aleo {
     struct PoolInfo {
          token1_name: field,
          token2_name: field,
          reserve1: u128,
          reserve2: u128,
          total_supply: u128,
     }

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

     struct Pair {
          addr: address,
          token_name: field,
     }
     
     mapping token_next_id: u8 => u64;
     mapping token_id_to_name: u64 => field;
     mapping token_name_to_info: field => TokenInfo;
     mapping token_name_to_owner: field => address;
     mapping account_token_to_amount: Pair => u128;
     mapping pool_id_to_pool: u64 => PoolInfo;
     mapping square_root_test: u64 => u128;

     transition init_dex(public dex_name: field) {
          return then finalize(self.caller);
     }

     finalize init_dex(public dex_owner: address) {
          Mapping::set(token_next_id, 0u8, 1u64);
          Mapping::set(token_next_id, 1u8, 1u64);
          Mapping::set(token_name_to_owner, 0field, dex_owner);
     }

     /* ---------------------------- Add new token ---------------------------- */
     transition add_new_token (public token_name: field, public decimals: u8) {
          return then finalize(token_name, decimals, self.caller);
     }
     finalize add_new_token(public token_name: field, public decimals: u8, public token_owner: address) {
          let try_get_token: TokenInfo = Mapping::get_or_use(
               token_name_to_info, 
               token_name, 
               TokenInfo {
                    id: 0u64,
                    name: 0field,
                    decimals: 0u8,
                    reserves: 0u128,
                    is_liquid_token: false,
               });
          assert_eq(try_get_token.id, 0u64);
          let token_id: u64 = Mapping::get(token_next_id, 0u8);

          try_get_token = TokenInfo {
               id: token_id,
               name: token_name,
               decimals,
               reserves: 0u128,
               is_liquid_token: false,
          };
          Mapping::set(token_next_id, 0u8, token_id + 1u64);
          Mapping::set(token_id_to_name, token_id, token_name);
          Mapping::set(token_name_to_info, token_name, try_get_token);
          Mapping::set(token_name_to_owner, token_name, token_owner);
     }

     /* ---------------------------- Mint by name, by id ---------------------------- */
     transition mint_by_name(public receiver: address, public amount: u128, public token_name: field) {
          // Mint the tokens publicly by invoking the computation on-chain.
          return then finalize(self.caller, receiver, amount, token_name);
     }

     finalize mint_by_name(public caller: address, public receiver: address, public amount: u128, public token_name: field) {
          let token_owner: address = Mapping::get(token_name_to_owner, token_name);
          assert_eq(token_owner, caller);

          let try_get_token: TokenInfo = Mapping::get(
               token_name_to_info, 
               token_name);
          // Only dex owner can mint liquid token via add liquidity function
          assert(!try_get_token.is_liquid_token);
          let new_token_info: TokenInfo = TokenInfo{
               id: try_get_token.id,
               name: try_get_token.name,
               decimals: try_get_token.decimals,
               reserves: try_get_token.reserves + amount,
               is_liquid_token: try_get_token.is_liquid_token,
          };

          let receiver_pair: Pair = Pair {
               addr: receiver,
               token_name: token_name,
          };

          let current_amount: u128 = Mapping::get_or_use(account_token_to_amount, receiver_pair, 0u128);
          Mapping::set(account_token_to_amount, receiver_pair, current_amount + amount);
          Mapping::set(token_name_to_info, token_name, new_token_info);
     }

     transition mint_by_id(public receiver: address, public amount: u128, public id: u64) {
          // Mint the tokens publicly by invoking the computation on-chain.
          return then finalize(self.caller, receiver, amount, id);
     }

     finalize mint_by_id(public caller: address, public receiver: address, public amount: u128, public id: u64) {
          let token_name: field = Mapping::get(token_id_to_name, id);
          let token_owner: address = Mapping::get(token_name_to_owner, token_name);
          assert_eq(token_owner, caller);

          let try_get_token: TokenInfo = Mapping::get(
               token_name_to_info, 
               token_name);
          assert(!try_get_token.is_liquid_token);

          let new_token_info: TokenInfo = TokenInfo{
               id: try_get_token.id,
               name: try_get_token.name,
               decimals: try_get_token.decimals,
               reserves: try_get_token.reserves + amount,
               is_liquid_token: try_get_token.is_liquid_token,
          };

          let receiver_pair: Pair = Pair {
               addr: receiver,
               token_name: token_name,
          };

          let current_amount: u128 = Mapping::get_or_use(account_token_to_amount, receiver_pair, 0u128);
          Mapping::set(account_token_to_amount, receiver_pair, current_amount + amount);
          Mapping::set(token_name_to_info, token_name, new_token_info);
     }

     /* ---------------------------- Transfer token, liquid token ---------------------------- */
     transition transfer_by_token_id(public receiver: address, public amount: u128, public token_id: u64) {
          // Transfer the tokens publicly, by invoking the computation on-chain.
          return then finalize(self.caller, receiver, amount, token_id);
     }
     finalize transfer_by_token_id(public sender: address, public receiver: address, public amount: u128, public token_id: u64) {
          assert(sender != receiver);
          let token_name: field = Mapping::get(token_id_to_name, token_id);

          let try_get_token: TokenInfo = Mapping::get(
               token_name_to_info, 
               token_name);

          let sender_pair: Pair = Pair {
               addr: sender,
               token_name: token_name,
          };
          
          // Decrements `account[sender]` by `amount`.
          // If `account[sender]` does not exist, it will be created.
          // If `account[sender] - amount` underflow, `transfer_public` is reverted.
          let sender_amount: u128 = Mapping::get_or_use(account_token_to_amount, sender_pair, 0u128);
          Mapping::set(account_token_to_amount, sender_pair, sender_amount - amount);


          // Increments `account[receiver]` by `amount`.
          // If `account[receiver]` does not exist, it will be created.
          // If `account[receiver] + amount` overflows, `transfer_public` is reverted.
          let receiver_pair: Pair = Pair {
               addr: receiver,
               token_name: token_name,
          };
          let receiver_amount: u128 = Mapping::get_or_use(account_token_to_amount, receiver_pair, 0u128);
          Mapping::set(account_token_to_amount, receiver_pair, receiver_amount + amount);
     }

     transition transfer_by_name(public receiver: address, public amount: u128, public token_name: field) {
          // Transfer the tokens publicly, by invoking the computation on-chain.
          return then finalize(self.caller, receiver, amount, token_name);
     }
     finalize transfer_by_name(public sender: address, public receiver: address, public amount: u128, public token_name: field) {
          assert(sender != receiver);
          let try_get_token: TokenInfo = Mapping::get(
               token_name_to_info, 
               token_name);
          assert(!try_get_token.is_liquid_token);
          
          let sender_pair: Pair = Pair {
               addr: sender,
               token_name: token_name,
          };
          
          // Decrements `account[sender]` by `amount`.
          // If `account[sender]` does not exist, it will be created.
          // If `account[sender] - amount` underflow, `transfer_public` is reverted.
          let sender_amount: u128 = Mapping::get_or_use(account_token_to_amount, sender_pair, 0u128);
          assert(sender_amount - amount >= 0u128);
          Mapping::set(account_token_to_amount, sender_pair, sender_amount - amount);


          // Increments `account[receiver]` by `amount`.
          // If `account[receiver]` does not exist, it will be created.
          // If `account[receiver] + amount` overflows, `transfer_public` is reverted.
          let receiver_pair: Pair = Pair {
               addr: receiver,
               token_name: token_name,
          };
          let receiver_amount: u128 = Mapping::get_or_use(account_token_to_amount, receiver_pair, 0u128);
          Mapping::set(account_token_to_amount, receiver_pair, receiver_amount + amount);
     }

     transition transfer_liquid_token(public receiver: address, public amount: u128, public liquid_token_id: u64) {
          // Transfer the tokens publicly, by invoking the computation on-chain.
          return then finalize(self.caller, receiver, amount, liquid_token_id);
     }

     finalize transfer_liquid_token(public sender: address, public receiver: address, public amount: u128, public liquid_token_id: u64) {
          let token_name: field = BHP256::hash_to_field(liquid_token_id);
          assert(sender != receiver);
          let try_get_token: TokenInfo = Mapping::get(
               token_name_to_info, 
               token_name);
          assert(try_get_token.is_liquid_token);

          let sender_pair: Pair = Pair {
               addr: sender,
               token_name: token_name,
          };
          // Decrements `account[sender]` by `amount`.
          // If `account[sender]` does not exist, it will be created.
          // If `account[sender] - amount` underflow, `transfer_public` is reverted.
          let sender_amount: u128 = Mapping::get_or_use(account_token_to_amount, sender_pair, 0u128);
          assert(sender_amount - amount >= 0u128);
          Mapping::set(account_token_to_amount, sender_pair, sender_amount - amount);

          // Increments `account[receiver]` by `amount`.
          // If `account[receiver]` does not exist, it will be created.
          // If `account[receiver] + amount` overflows, `transfer_public` is reverted.
          let receiver_pair: Pair = Pair {
               addr: receiver,
               token_name: token_name,
          };
          let receiver_amount: u128 = Mapping::get_or_use(account_token_to_amount, receiver_pair, 0u128);
          Mapping::set(account_token_to_amount, receiver_pair, receiver_amount + amount);
     }

     /* ---------------------------- Create new pool ---------------------------- */
     /* ---------------------------- And init liquidity ---------------------------- */
     transition create_new_pool(
          public token1_name: field,
          public token2_name: field) {
          return then finalize(token1_name, token2_name);
     }

     finalize create_new_pool(token1_name: field, token2_name: field) {
          let pool_info: PoolInfo = PoolInfo {
               token1_name,
               token2_name,
               reserve1: 0u128,
               reserve2: 0u128,
               total_supply: 0u128,
          };
          // token.leo/add_new_liquidity_token();
          let current_liquidity_id: u64 = Mapping::get(token_next_id, 1u8);

          let token_name: field = BHP256::hash_to_field(current_liquidity_id);
          let expect_true: bool = Mapping::contains(token_name_to_info, token_name); 
          assert(!expect_true);

          let token_id: u64 = Mapping::get(token_next_id, 0u8);

          let new_token_info: TokenInfo = TokenInfo {
               id: token_id,
               name: token_name,
               decimals: 6u8,
               reserves: 0u128,
               is_liquid_token: true,
          };
          Mapping::set(token_next_id, 0u8, token_id + 1u64);
          Mapping::set(token_next_id, 1u8, current_liquidity_id + 1u64);
          Mapping::set(token_id_to_name, token_id, token_name);
          Mapping::set(token_name_to_info, token_name, new_token_info);
          Mapping::set(pool_id_to_pool, current_liquidity_id, pool_info);
     }

     /* ---------------------------- Add, remove liquidity ---------------------------- */
     transition add_liquidity(amount1: u128, amount2: u128, pool_id: u64) {
          return then finalize(self.caller, amount1, amount2, pool_id);
     }

     finalize add_liquidity(caller: address, amount1: u128, amount2: u128, pool_id: u64) {
          let dex_owner: address = Mapping::get(token_name_to_owner, 0field);
          assert(caller != dex_owner);
          let pool_info: PoolInfo = Mapping::get(pool_id_to_pool, pool_id);

          let token1_name: field = pool_info.token1_name;
          let token2_name: field = pool_info.token2_name;

          let caller_pair_1: Pair = Pair {
               addr: caller,
               token_name: token1_name,
          };

          let caller_pair_2: Pair = Pair {
               addr: caller,
               token_name: token2_name,
          };

          let dex_owner_pair_1: Pair = Pair {
               addr: dex_owner,
               token_name: token1_name,
          };

          let dex_owner_pair_2: Pair = Pair {
               addr: dex_owner,
               token_name: token2_name,
          };

          // Transfer token 1 to dex_owner
          let sender_amount_1: u128 = Mapping::get_or_use(account_token_to_amount, caller_pair_1, 0u128);
          assert(sender_amount_1 - amount1 >= 0u128);
          Mapping::set(account_token_to_amount, caller_pair_1, sender_amount_1 - amount1);
          let receiver_amount_1: u128 = Mapping::get_or_use(account_token_to_amount, dex_owner_pair_1, 0u128);
          Mapping::set(account_token_to_amount, dex_owner_pair_1, receiver_amount_1 + amount1);

          // Transfer token 2 to dex_owner
          let sender_amount_2: u128 = Mapping::get_or_use(account_token_to_amount, caller_pair_2, 0u128);
          assert(sender_amount_2 - amount2 >= 0u128);
          Mapping::set(account_token_to_amount, caller_pair_2, sender_amount_2 - amount2);
          let receiver_amount_2: u128 = Mapping::get_or_use(account_token_to_amount, dex_owner_pair_2, 0u128);
          Mapping::set(account_token_to_amount, dex_owner_pair_2, receiver_amount_2 + amount2);

          //User must makes sure that dy/dx = y/x in providing Liquidity
          // if (pool_info.reserve1 > 0u128 || pool_info.reserve2 > 0u128) {
          //      assert_eq(pool_info.reserve1 * amount2, pool_info.reserve2 * amount1); // Chỗ này anh nghĩ không chính xác được tuyệt đối? Em test chưa?
          // }

          //Mint shares
          //f(x,y) = value of liquidity = sqrt(xy)
          //s = dx / x * T = dy /y * T
          let shares: u128 = 0u128;
          if pool_info.total_supply == 0u128 {
               let mul_shares: u128 = amount1 * amount2;
               if (mul_shares > 3u128) {
                    let left: u128 = 1u128;
                    let right: u128 = mul_shares;

                    for i: u128 in 0u128..128u128 {
                         let mid: u128 = (left + right) / 2u128;
                         if mid.mul_wrapped(mid) <= mul_shares {
                         left = mid + 1u128;
                         } else {
                         right = mid - 1u128;
                         }
                    }
                    shares = right;
               } else {
                    shares = 1u128;
               }
          } else {
               let shares1: u128 = (amount1 * pool_info.total_supply).div_wrapped(pool_info.reserve1 + 1u128);
               let shares2: u128 = (amount2 * pool_info.total_supply).div_wrapped(pool_info.reserve2 + 1u128);
               if shares1 > shares2 {
                    shares = shares2;
               } else {
                    shares = shares1;
               }
          }
          assert(shares > 0u128);

          //  mint_liquid_token(shares, pool_id);
          let token_name: field = BHP256::hash_to_field(pool_id);

          let try_get_token: TokenInfo = Mapping::get(
                    token_name_to_info,
                    token_name);
          assert(try_get_token.is_liquid_token);

          let new_token_info: TokenInfo = TokenInfo {
               id: try_get_token.id,
               name: try_get_token.name,
               decimals: try_get_token.decimals,
               reserves: try_get_token.reserves + shares,
               is_liquid_token: try_get_token.is_liquid_token,
          };

          let lp_caller_pair: Pair = Pair {
               addr: dex_owner,
               token_name: token_name,
          };

          let current_amount: u128 = Mapping::get_or_use(account_token_to_amount, lp_caller_pair, 0u128);
          Mapping::set(account_token_to_amount, lp_caller_pair, current_amount + shares);
          Mapping::set(token_name_to_info, token_name, new_token_info);

          let new_pool_info: PoolInfo = PoolInfo {
               token1_name: pool_info.token1_name,
               token2_name: pool_info.token2_name,
               reserve1: pool_info.reserve1 + amount1,
               reserve2: pool_info.reserve2 + amount2,
               total_supply: pool_info.total_supply + shares
          };
          Mapping::set(pool_id_to_pool, pool_id, new_pool_info);
     }

     transition remove_liquidity(public shares: u128, public pool_id: u64) {
          return then finalize(self.caller, shares, pool_id);
     }

     finalize remove_liquidity(public caller: address, public shares: u128, public pool_id: u64) {
          let dex_owner: address = Mapping::get(token_name_to_owner, 0field);
          assert(caller != dex_owner);
          let pool_info: PoolInfo = Mapping::get(pool_id_to_pool, pool_id);

          // Burn_liquid_token(shares, pool_id);
          let token_name: field = BHP256::hash_to_field(pool_id);

          let try_get_token: TokenInfo = Mapping::get(
               token_name_to_info,
               token_name);
          assert(try_get_token.is_liquid_token);

          let lp_caller_pair: Pair = Pair {
               addr: caller,
               token_name: token_name,
          };
          
          let caller_amount: u128 = Mapping::get_or_use(account_token_to_amount, lp_caller_pair, 0u128);
          Mapping::set(account_token_to_amount, lp_caller_pair, caller_amount - shares);

          let new_token_info: TokenInfo = TokenInfo{
               id: try_get_token.id,
               name: try_get_token.name,
               decimals: try_get_token.decimals,
               reserves: try_get_token.reserves - shares,
               is_liquid_token: try_get_token.is_liquid_token,
          };
          Mapping::set(token_name_to_info, token_name, new_token_info);

          let amount1: u128 = (shares * pool_info.reserve1) / pool_info.total_supply;
          let amount2: u128 = (shares * pool_info.reserve2) / pool_info.total_supply;
          assert(amount1 > 0u128);
          assert(amount2 > 0u128);

          pool_info = PoolInfo {
               token1_name: pool_info.token1_name,
               token2_name: pool_info.token2_name,
               reserve1: pool_info.reserve1 - amount1,
               reserve2: pool_info.reserve2 - amount2,
               total_supply: pool_info.total_supply - shares
          };

          // Withdraw token 1 to caller
          let token1_name: field = pool_info.token1_name;
          let token2_name: field = pool_info.token2_name;

          let caller_pair_1: Pair = Pair {
               addr: caller,
               token_name: token1_name,
          };

          let caller_pair_2: Pair = Pair {
               addr: caller,
               token_name: token2_name,
          };

          let dex_owner_pair_1: Pair = Pair {
               addr: dex_owner,
               token_name: token1_name,
          };

          let dex_owner_pair_2: Pair = Pair {
               addr: dex_owner,
               token_name: token2_name,
          };


          let sender_amount_1: u128 = Mapping::get_or_use(account_token_to_amount, caller_pair_1, 0u128);
          Mapping::set(account_token_to_amount, caller_pair_1, sender_amount_1 + amount1);
          let receiver_amount_1: u128 = Mapping::get_or_use(account_token_to_amount, dex_owner_pair_1, 0u128);
          Mapping::set(account_token_to_amount, dex_owner_pair_1, receiver_amount_1 - amount1);

          // Withdraw token 2 to caller
          let sender_amount_2: u128 = Mapping::get_or_use(account_token_to_amount, caller_pair_2, 0u128);
          Mapping::set(account_token_to_amount, caller_pair_2, sender_amount_2 + amount2);
          let receiver_amount_2: u128 = Mapping::get_or_use(account_token_to_amount, dex_owner_pair_2, 0u128);
          Mapping::set(account_token_to_amount, dex_owner_pair_2, receiver_amount_2 - amount2);
          Mapping::set(pool_id_to_pool, pool_id, pool_info);
     }

     /* ---------------------------- Swap ---------------------------- */
     transition swap(public amount_in: u128, public pool_id: u64, public token_name: field) {
          return then finalize(self.caller, amount_in, pool_id, token_name);
     }

     finalize swap(public caller: address, public amount_in: u128, public pool_id: u64, public token_name: field) {
          let dex_owner: address = Mapping::get(token_name_to_owner, 0field);
          assert(caller != dex_owner);
          let pool_info: PoolInfo = Mapping::get(pool_id_to_pool, pool_id);

          assert(token_name == pool_info.token1_name || token_name == pool_info.token2_name);
          assert(amount_in > 0u128);

          // Transfer given token name to dex_owner
          let caller_pair: Pair = Pair {
               addr: caller,
               token_name: token_name,
          };

          let dex_owner_pair: Pair = Pair {
               addr: dex_owner,
               token_name: token_name,
          };

          let sender_amount: u128 = Mapping::get_or_use(account_token_to_amount, caller_pair, 0u128);
          assert(sender_amount - amount_in > 0u128);
          Mapping::set(account_token_to_amount, caller_pair, sender_amount - amount_in);
          let receiver_amount: u128 = Mapping::get_or_use(account_token_to_amount, dex_owner_pair, 0u128);
          Mapping::set(account_token_to_amount, dex_owner_pair, receiver_amount + amount_in);

          if token_name == pool_info.token1_name {
               let reserve_in: u128 = pool_info.reserve1;
               let reserve_out: u128 = pool_info.reserve2;

               let amount_out: u128 = (reserve_out * amount_in) / (reserve_in + amount_in);

               let caller_pair_2: Pair = Pair {
                    addr: caller,
                    token_name: pool_info.token2_name,
               };

               let dex_owner_pair_2: Pair = Pair {
                    addr: dex_owner,
                    token_name: pool_info.token2_name,
               };

               // Transfer token 2 of pool id from dex owner to caller
               let sender_amount_2: u128 = Mapping::get_or_use(account_token_to_amount, caller_pair_2, 0u128);
               Mapping::set(account_token_to_amount, caller_pair_2, sender_amount_2 + amount_out);
               let receiver_amount_2: u128 = Mapping::get_or_use(account_token_to_amount, dex_owner_pair_2, 0u128);
               assert(receiver_amount_2 - amount_out > 0u128);
               Mapping::set(account_token_to_amount, dex_owner_pair_2, receiver_amount_2 - amount_out);

               pool_info = PoolInfo {
                    token1_name: pool_info.token1_name,
                    token2_name: pool_info.token2_name,
                    reserve1: pool_info.reserve1 + amount_in,
                    reserve2: pool_info.reserve2 - amount_out,
                    total_supply: pool_info.total_supply,
               };
               Mapping::set(pool_id_to_pool, pool_id, pool_info);
          } else {
               let reserve_in: u128 = pool_info.reserve2;
               let reserve_out: u128 = pool_info.reserve1;

               let amount_out: u128 = (reserve_out * amount_in) / (reserve_in + amount_in);

               // Transfer token 1 of pool id from dex owner to caller
               let caller_pair_1: Pair = Pair {
                    addr: caller,
                    token_name: pool_info.token1_name,
               };

               let dex_owner_pair_1: Pair = Pair {
                    addr: dex_owner,
                    token_name: pool_info.token1_name,
               };
               let sender_amount_1: u128 = Mapping::get_or_use(account_token_to_amount, caller_pair_1, 0u128);
               Mapping::set(account_token_to_amount, caller_pair_1, sender_amount_1 + amount_out);
               let receiver_amount_1: u128 = Mapping::get_or_use(account_token_to_amount, dex_owner_pair_1, 0u128);
               assert(receiver_amount_1 - amount_out > 0u128);
               Mapping::set(account_token_to_amount, dex_owner_pair_1, receiver_amount_1 - amount_out);

               pool_info = PoolInfo {
                    token1_name: pool_info.token1_name,
                    token2_name: pool_info.token2_name,
                    reserve1: pool_info.reserve1 - amount_out,
                    reserve2: pool_info.reserve2 + amount_in,
                    total_supply: pool_info.total_supply,
               };
               Mapping::set(pool_id_to_pool, pool_id, pool_info);
          }
     }
}
