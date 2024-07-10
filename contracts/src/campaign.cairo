use starknet::ContractAddress;

#[starknet::component]
mod CampaignComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address};
    use tokengiver::interfaces::ITokenGiverNft::{
        ITokenGiverNftDispatcher, ITokenGiverNftDispatcherTrait
    };
    use tokengiver::interfaces::IRegistry::{
        IRegistryDispatcher, IRegistryDispatcherTrait, IRegistryLibraryDispatcher
    };
    use tokengiver::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use tokengiver::interfaces::ICampaign::ICampaign;
    use tokengiver::base::types::Campaign;
    use tokengiver::base::errors::Errors::NOT_CAMPAIGN_OWNER;


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        campaign: LegacyMap<ContractAddress, Campaign>
    }

    // *************************************************************************
    //                            EVENT
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CreateCampaign: CreateCampaign
    }

    #[derive(Drop, starknet::Event)]
    struct CreateCampaign {
        #[key]
        owner: ContractAddress,
        #[key]
        campaign_address: ContractAddress,
        token_id: u256,
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[embeddable_as(TokenGiverCampaign)]
    impl CampaignImpl<
        TContractState, +HasComponent<TContractState>
    > of ICampaign<ComponentState<TContractState>> {
        fn create_campaign(
            ref self: ComponentState<TContractState>,
            token_giverNft_contract_address: ContractAddress,
            registry_hash: felt252,
            implementation_hash: felt252,
            salt: felt252,
            recipient: ContractAddress
        ) -> ContractAddress {
            let owns_tokenGivernft = IERC721Dispatcher {
                contract_address: token_giverNft_contract_address
            }
                .balance_of(recipient);
            if owns_tokenGivernft == 0 {
                ITokenGiverNftDispatcher { contract_address: token_giverNft_contract_address }
                    .mint_token_giver_nft(recipient);
            }
            let token_id = ITokenGiverNftDispatcher {
                contract_address: token_giverNft_contract_address
            }
                .get_user_token_id(recipient);

            let campaign_address = IRegistryLibraryDispatcher {
                class_hash: registry_hash.try_into().unwrap()
            }
                .create_account(
                    implementation_hash, token_giverNft_contract_address, token_id, salt
                );
            let new_campaign = Campaign {
                campaign_address, campaign_owner: recipient, metadata_URI: "",
            };
            self.campaign.write(campaign_address, new_campaign);
            self.emit(CreateCampaign { owner: recipient, campaign_address, token_id });
            campaign_address
        }

        /// @notice set campaign metadata_uri (`banner_image, description, campaign_image` to be uploaded to arweave or ipfs)
        /// @params campaign_address the targeted campaign address
        /// @params metadata_uri the campaign CID
        fn set_campaign_metadata_uri(
            ref self: ComponentState<TContractState>,
            campaign_address: ContractAddress,
            metadata_uri: ByteArray
        ) {
            let mut campaign: Campaign = self.campaign.read(campaign_address);
            assert(get_caller_address() == campaign.campaign_owner, NOT_CAMPAIGN_OWNER);
            campaign.metadata_URI = metadata_uri;
            self.campaign.write(campaign_address, campaign);
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************

        // @notice returns the campaign struct of a campaign address
        // @params campaign_address the targeted campaign address
        fn get_campaign(
            ref self: ComponentState<TContractState>, campaign_address: ContractAddress
        ) -> Campaign {
            self.campaign.read(campaign_address)
        }

        fn get_campaign_metadata(
            self: @ComponentState<TContractState>, campaign_address: ContractAddress
        ) -> ByteArray {
            let campaign: Campaign = self.campaign.read(campaign_address);
            campaign.metadata_URI
        }
    }
}
