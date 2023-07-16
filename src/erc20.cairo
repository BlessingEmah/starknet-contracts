use starknet::ContractAddress;

#[starknet::interface]

trait IERC20 <TContractState> {
    fn get_name(self: @TContractState) -> felt252;
    fn get_symbol(self: @TContractState) ->felt252;
    fn get_decimals(self: @TContractState) -> u8;
    fn get_total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender:ContractAddress) ->u256;
    fn transfer( ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from (ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) ;
    fn approve(ref self : TContractState, spender: ContractAddress, amount:u256);
    fn increase_allowance (ref self: TContractState, spender: ContractAddress, added_value: u256);
    fn decrease_allowance (ref self: TContractState, spender: ContractAddress, subtracted_value : u256);
}

#[starknet::contract]

mod ERC20 {
    use starknet::{get_caller_address, ContractAddress, contract_address_const};
    use zeroable::Zeroable;
    use super::IERC20;

    #[storage]
    struct Storage {
        name: felt252,
        symbol : felt252,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap<ContractAddress, u256>,
        allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
    }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval{
        owner : ContractAddress,
        spender : ContractAddress,
        value : u256,
    }


    #[constructor]
    fn constructor (
        ref self: ContractState,
        _name : felt252,
        _symbol : felt252,
        _decimals :u8,
        _initial_supply : u256,
        recipient :ContractAddress
    )  {
        assert(!recipient.is_zero(), 'transfer to zero address');
        self.name.write(_name);
        self.symbol.write(_symbol);
        self.decimals.write(_decimals);
        self.total_supply.write(_initial_supply);
        self.balances.write(recipient, _initial_supply);

        self.emit(
             Transfer {
                 from: contract_address_const::<0>(),
                 to: recipient,
                 value: _initial_supply,
            }
        );

    }

    #[external(v0)]
    impl IERC20Impl of IERC20<ContractState> {
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn get_decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn get_total_supply(self : @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account : 
        ContractAddress) -> u256 {
            self.balances.read(account)
        }

        fn allowance (self: @ContractState, owner: ContractAddress,
        spender: ContractAddress) -> u256 {
            self.allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient:ContractAddress, amount: u256) {
            let caller = get_caller_address();
            self.transfer_helper (caller, recipient, amount);
        }

        fn transfer_from (ref self: ContractState, sender: ContractAddress, recipient: ContractAddress,
        amount: u256) {
            let caller = get_caller_address();
            self.spend_allowance(sender, caller, amount);
            self.transfer_helper(sender, recipient, amount);
        }

        fn approve(ref self:ContractState, spender: ContractAddress,
        amount: u256) {
            let owner = get_caller_address();
            self.approve_helper(owner, spender, amount);
        }

        fn increase_allowance(ref self:ContractState, spender: ContractAddress,
         added_value: u256) {
             let owner = get_caller_address();
             self.approve_helper(owner,spender, self.allowances.read((owner,spender))+ added_value);
         }

        fn decrease_allowance(ref self:ContractState, spender: ContractAddress, 
        subtracted_value: u256){
            let owner = get_caller_address();
            self.approve_helper(owner, spender, self.allowances.read((owner, spender)) - subtracted_value);
        }


    }

    #[generate_trait]
    impl ERC20HelperImpl of ERC20HelperTrait {
        fn transfer_helper (ref self: ContractState, owner: ContractAddress, recipient:
        ContractAddress, amount: u256) {
            assert(!owner.is_zero(), 'owner is a zero address');
            assert(!recipient.is_zero(), 'recipient is a 0 address');

            self.balances.write(owner,self.balances.read(owner) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);


            self.emit(
                Transfer {
                    from: owner,
                    to: recipient,
                    value: amount
                }    
             );
        }

        fn spend_allowance(ref self: ContractState, owner: ContractAddress, spender:
         ContractAddress, amount: u256) {
             let current_allowance = self.allowances.read((owner, spender));
             let ONES_MASK = 0xffffffffffffffffffffffffff_u128;

             let is_unlimited_allowance = current_allowance.low == ONES_MASK &&
             current_allowance.high == ONES_MASK;

             if !is_unlimited_allowance {
                 self.allowances.write((owner, spender),
                 current_allowance - amount);
             }
         }

         fn approve_helper(ref self: ContractState, owner: ContractAddress, spender:
         ContractAddress, amount: u256) {
             assert(!owner.is_zero(), 'approve from a 0 address');
             assert(!spender.is_zero(), 'approve to a 0 address');

             self.allowances.write((owner, spender), amount);

             self.emit(
                 Approval {
                     owner,
                     spender,
                     value: amount,
                 }       
             );
         }
    }


}
