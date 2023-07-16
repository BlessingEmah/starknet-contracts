#[starknet::contract]

mod ENS {
    use starknet::{get_caller_address, ContractAddress};

    #[storage]
    struct Storage {
        names: LegacyMap<ContractAddress, felt252>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredName : StoredName
    }

   #[derive (Drop, starknet::Event)]
   struct StoredName {
       address : ContractAddress,
       name : felt252,

   }

    #[constructor]
    fn constructor (ref self: ContractState, _address: ContractAddress, _name: felt252) {
    self.names.write(_address, _name);
    }   

    #[external(v0)]
    #[generate_trait]
    impl ENSImpl of ENSTrait {
        fn store_name(ref self: ContractState, _name:felt252) {
            let caller = get_caller_address();
            self.names.write(caller, _name);

            self.emit(
                StoredName {
                    address : caller,
                    name : _name,
                }
            )
 
        } 
    }

    fn get_name(self : @ContractState, _address: ContractAddress) -> felt252 {
        self.names.read(_address)

    }

}
