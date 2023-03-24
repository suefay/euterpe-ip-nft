// SPDX-License-Identifier: Apache-2.0

/// Euterpe composable IP NFT implementation.
module euterpe_ip_nft::composable_ip_nft {
    use sui::transfer;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::dynamic_field as field;
    use sui::tx_context::{Self, TxContext};
    
    use euterpe_ip_nft::music_ip_nft::EuterpeMusicIPNFT;
    use euterpe_ip_nft::movie_ip_nft::EuterpeMovieIPNFT;

    /// Error for non existing field.
    const EFieldDoesNotExist: u64 = 0;

    /// EuterpeComposableIPNFT defines the composable IP NFT which comprises the music IP NFT and movie IP NFT.
    struct EuterpeComposableIPNFT has key, store {
        id: UID
    }

    /// Emitted when a token is composed.
    struct ComposeEvent has copy, drop {
        /// The object ID of the composed token
        object_id: ID,
        /// The object ID of the music IP NFT which is a component of the composed token
        music_object_id: ID,
        /// The object ID of the movie IP NFT which is a component of the composed token
        movie_object_id: ID,
        /// The owner of the composed token
        account: address
    }

    /// Emitted when a token is decomposed.
    struct DecomposeEvent has copy, drop {
        /// The object ID of the token
        object_id: ID,
        /// The original owner of the token
        account: address
    }

    /// Compose a new token given the music IP NFT and movie IP NFT.
    public entry fun compose(
        music_ip_nft: EuterpeMusicIPNFT,
        movie_ip_nft: EuterpeMovieIPNFT,
        ctx: &mut TxContext
    ) {
        let music_object_id = object::id(&music_ip_nft);
        let movie_object_id = object::id(&movie_ip_nft);

        let new_token = EuterpeComposableIPNFT {
            id: object::new(ctx)
        };

        field::add(&mut new_token.id, music_object_id, music_ip_nft);
        field::add(&mut new_token.id, movie_object_id, movie_ip_nft);

        event::emit(ComposeEvent {
            object_id: object::uid_to_inner(&new_token.id), 
            music_object_id: music_object_id,
            movie_object_id: movie_object_id,
            account: tx_context::sender(ctx)
        });

        transfer::transfer(new_token, tx_context::sender(ctx))
    }

    /// Decompose the token to the original music IP NFT and movie IP NFT.
    public entry fun decompose(
        composable_ip_nft: EuterpeComposableIPNFT,
        music_object_id: ID,
        movie_object_id: ID,
        ctx: &mut TxContext
    ) {
        let EuterpeComposableIPNFT { id } = composable_ip_nft;

        assert!(field::exists_(&id, music_object_id), EFieldDoesNotExist);
        assert!(field::exists_(&id, movie_object_id), EFieldDoesNotExist);

        let music_ip_nft = field::remove<ID, EuterpeMusicIPNFT>(&mut id, music_object_id);
        let movie_ip_nft = field::remove<ID, EuterpeMovieIPNFT>(&mut id, movie_object_id);

        event::emit(DecomposeEvent {
            object_id: object::uid_to_inner(&id),
            account: tx_context::sender(ctx)
        });

        object::delete(id);

        transfer::transfer(music_ip_nft, tx_context::sender(ctx));
        transfer::transfer(movie_ip_nft, tx_context::sender(ctx))
    }
}
