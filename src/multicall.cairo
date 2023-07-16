#[starknet :: contract]

mod Multicall {
    use starknet::{get_caller_address, call_contract_syscall, get_block_timestamp, 
    get_tx_info, VALIDATED, acount::Call};
    use box::BoxTrait;
    use array::{ArrayTrait, SpanTrait}; 
    use ecdsa::check_ecdsa_signature;
    use zeroable::Zeroable;


    #[storage]
    struct Storage {
        public_key: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _public_key: felt252){
        self.public_key.write(_public_key);
    }

    #[external(v0)]
    fn _validate_deploy(self: @ContractState, class_hash:felt252, contract_address_salt: felt252, 
    entry_point_selector: felt252) -> felt252 {
        self.validate_transaction();
    }



    #[generate_trait]
    impl of MulticallImpl of MulticallTrait {
        fn validate_transaction(self: @ContractState) -> felt252{
             
             let tx_info = get_tx_info().unbox();
             let signature = tx_info.signature;
             asser(signature.len() ==2_u32, 'invalid signature len');

             assert(
                 check_ecdsa_signature(
                     message_hash: tx_info.transaction_hash,
                     public_key: _public_key,
                     signature_r :*signature[0_u32],
                     signature_s :*signature[1_u32],     
                 ),
                 'invalid signature'
             );
             VALIDATED

        }

    }
}
