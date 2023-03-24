// SPDX-License-Identifier: Apache-2.0

/// Euterpe movie IP NFT implementation.
module euterpe_ip_nft::movie_ip_nft {
    use sui::transfer;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};

    /// OwnerCap is the capability to mint tokens.
    struct OwnerCap has key, store {
        id: UID
    }
    
    /// EuterpeMovieIPNFT defines the NFT for the Euterpe movie IP.
    struct EuterpeMovieIPNFT has key, store {
        id: UID,
        /// The metadata url of the token
        url: Url
    }

    /// Emitted when a token is mint.
    struct MintEvent has copy, drop {
        /// The object ID of the token
        object_id: ID,
        /// The owner of the token
        account: address
    }

    /// Emitted when a token is burned.
    struct BurnEvent has copy, drop {
        /// The object ID of the token
        object_id: ID,
        /// The original owner of the token
        account: address
    }

    /// Module initializer to create the OwnerCap object.
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            OwnerCap { id: object::new(ctx) }, 
            tx_context::sender(ctx)
        )
    }

    /// Mint a token.
    public entry fun mint(
        _: &OwnerCap,
        recipient: address,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let token = EuterpeMovieIPNFT {
            id: object::new(ctx),
            url: url::new_unsafe_from_bytes(url)
        };

        event::emit(MintEvent { object_id: object::uid_to_inner(&token.id), account: recipient });

        transfer::transfer(token, recipient)
    }

    /// Burn the specified token.
    public entry fun burn(
        token: EuterpeMovieIPNFT,
        ctx: &mut TxContext
    ) {
        let EuterpeMovieIPNFT { id, url: _ } = token;

        event::emit(BurnEvent { object_id: object::uid_to_inner(&id), account: tx_context::sender(ctx) });

        object::delete(id)
    }
}
