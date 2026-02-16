// ========================================================================
// Module: pokemon_marketplace
//
// A smart contract demonstrating Sui Move’s resource model,
// vector handling, events, and best practices. This module implements:
//   1. A centralized marketplace for Pokémon card NFTs.
//   2. A cap on total mintable cards (MAX_SUPPLY).
//   3. Escrow of listed cards for sale in a vector, with utility to retrieve listings.
//   4. Methods to buy/sell listed cards.
//   5. Administrative controls (fee updates, freeze/unfreeze).
// ========================================================================
module pokemon_marketplace::marketplace {
    use std::string::String;                                // String type
    use sui::event;                                         // Emitting events
    use sui::coin::{Self, Coin};                            // Coin operations
    use sui::sui::SUI;
    use std::string;                                      // Native SUI coin

    // -------------------------------------------------------------------------
    // Error Codes
    // Enumerated abort reasons for clarity when a function fails.
    // -------------------------------------------------------------------------
    const E_INSUFFICIENT_PAYMENT: u64 = 0;  // Buyer didn't provide enough SUI
    const E_NOT_FOR_SALE:          u64 = 1;  // Attempt to buy/delist a non‑listed card
    const E_NOT_OWNER:             u64 = 2;  // Caller is not the owner of the card
    const E_MARKET_FROZEN:         u64 = 3;  // Market operations are paused
    const E_MAX_SUPPLY_REACHED:    u64 = 4;  // Mint limit has been reached
    const E_INVALID_METADATA:      u64 = 5;  // Invalid parameter (e.g., fee > 10%)

    // -------------------------------------------------------------------------
    // Validations
    // -------------------------------------------------------------------------
    const MAX_SUPPLY:              u64 = 1025; // Max number of cards that can be minted
    const MAX_NAME_LEN: u64 = 64;
    const MAX_TYPE_LEN: u64 = 32;

    // -------------------------------------------------------------------------
    // Resource & Event Structs
    // -------------------------------------------------------------------------

    /// AdminCap: Grants administrative privileges (fee updates, freeze/unfreeze).
    /// Must be held by an address to call privileged functions.
    public struct AdminCap has key, store {
        id: UID
    }

    /// Marketplace: Central on‑chain resource tracking state and configuration.
    /// - `fee_bps`: Basis points (e.g. 250 = 2.5%).
    /// - `fee_dest`: Address receiving fees.
    /// - `total_vol`: Cumulative SUI processed by market.
    /// - `frozen`: If true, mint/list/buy/delist operations abort.
    /// - `minted`: Tracks count of minted cards (enforces MAX_SUPPLY).
    /// - `listings`: Vector of `Card` resources held in escrow.
    /// - `listed`: Mirror of `listings.length()` for quick stats.
    public struct Marketplace has key, store {
        id:        UID,
        fee_bps:   u64,
        fee_dest:  address,
        total_vol: u64,
        frozen:    bool,
        minted:    u64,
        listings:  vector<Card>,
        listed:    u64
    }

    /// Card: Represents an NFT with metadata and sale state.
    /// - `id`: Unique object ID.
    /// - `owner`: Current owner address.
    /// - `name`, `pokemon_type`: Metadata fields.
    /// - `price`: Listing price in SUI (0 if not for sale).
    /// - `for_sale`: True when actively listed.
    /// - `minted_at`: Epoch when minted.
    public struct Card has key, store {
        id:           UID,
        owner:        address,
        name:         String,
        pokemon_type: String,
        price:        u64,
        for_sale:     bool,
        minted_at:    u64
    }

    /// MarketplaceCreated: Emitted once when the market is initialized.
    public struct MarketplaceCreated has copy, drop {
        market_id: ID,
        admin:     address,
        fee_bps:   u64
    }

    /// CardCreated: Emitted when a new card NFT is minted.
    public struct CardCreated has copy, drop {
        card_id:       ID,
        owner:         address,
        name:          String,
        pokemon_type:  String,
        minted_at:     u64
    }

    /// CardListed: Emitted when a card is escrowed for sale.
    public struct CardListed has copy, drop {
        card_id:      ID,
        seller:       address,
        price:        u64,
        pokemon_type: String
    }

    /// CardPurchased: Emitted upon successful purchase of a listed card.
    public struct CardPurchased has copy, drop {
        card_id:      ID,
        seller:       address,
        buyer:        address,
        price:        u64,
        fee:          u64,
        pokemon_type: String
    }

    // -------------------------------------------------------------------------
    // Helper: remove_listing
    //
    // Internal utility to find a Card in `market.listings` by its ID,
    // remove it via swap_remove (O(1)), decrement `listed`, and return the Card.
    // Aborts if not found.
    // -------------------------------------------------------------------------
    fun remove_listing(market: &mut Marketplace, cid: ID): Card {
        let len = vector::length(&market.listings);
        let mut i = 0;
        while (i < len) {
            let c_ref = vector::borrow(&market.listings, i);
            if (object::id(c_ref) == cid) {
                let card = vector::swap_remove(&mut market.listings, i);
                market.listed = market.listed - 1;
                return card
            };
            i = i + 1;
        };
        abort E_NOT_FOR_SALE
    }

    // -------------------------------------------------------------------------
    // Core Entry Functions
    // -------------------------------------------------------------------------

    /// init: Create the Marketplace resource and transfer AdminCap to sender.
    /// - Initializes all counters to zero and an empty escrow vector.
    /// - Emits `MarketplaceCreated`.
    fun init(ctx: &mut TxContext) {
        // Create AdminCap & Marketplace
        let admin_cap = AdminCap { id: object::new(ctx) };
        let market = Marketplace {
            id:        object::new(ctx),
            fee_bps:   250,                     // Default 2.5%
            fee_dest:  tx_context::sender(ctx),
            total_vol: 0,
            frozen:    false,
            minted:    0,
            listings:  vector::empty<Card>(),
            listed:    0
        };

        // Emit creation event
        event::emit(MarketplaceCreated {
            market_id: object::id(&market),
            admin:     tx_context::sender(ctx),
            fee_bps:   250
        });

        // Transfer AdminCap to caller (kept private)
        transfer::transfer(admin_cap, tx_context::sender(ctx));

        // Make the market globally accessible
        transfer::public_share_object(market);
    }

    /// new: Mint a new Pokémon Card NFT (up to MAX_SUPPLY).
    /// - Ensures `minted < MAX_SUPPLY`.
    /// - Increments `minted` and emits `CardCreated`.
    /// - Transfers the new Card to the minter.
    public entry fun new(
        name: String,
        pokemon_type: String,
        market: &mut Marketplace,
        ctx: &mut TxContext
    ) {
        assert!(market.minted < MAX_SUPPLY, E_MAX_SUPPLY_REACHED);
        assert!(string::length(&name) <= MAX_NAME_LEN, E_INVALID_METADATA);
        assert!(string::length(&pokemon_type) <= MAX_TYPE_LEN, E_INVALID_METADATA);

        let owner = tx_context::sender(ctx);
        let now   = tx_context::epoch(ctx);

        let card = Card {
            id:           object::new(ctx),
            owner,
            name,
            pokemon_type,
            price:        0,
            for_sale:     false,
            minted_at:    now
        };

        market.minted = market.minted + 1;
        event::emit(CardCreated {
            card_id:       object::id(&card),
            owner,
            name:          card.name,
            pokemon_type:  card.pokemon_type,
            minted_at:     now
        });

        transfer::transfer(card, owner);
    }

    /// list_card: Escrow a user’s Card NFT for sale.
    /// - Caller must own the Card and market must be active.
    /// - Pushes into `market.listings` and updates counter.
    /// - Emits `CardListed`.
    public entry fun list_card(
        mut card: Card,
        price: u64,
        market: &mut Marketplace,
        ctx: &mut TxContext
    ) {
        assert!(!market.frozen, E_MARKET_FROZEN);
        let seller = tx_context::sender(ctx);
        assert!(card.owner == seller, E_NOT_OWNER);

        card.price       = price;
        card.for_sale    = true;
        let cid          = object::id(&card);
        let ptype_copy   = card.pokemon_type;

        vector::push_back(&mut market.listings, card);
        market.listed = market.listed + 1;

        event::emit(CardListed {
            card_id:      cid,
            seller,
            price,
            pokemon_type: ptype_copy
        });
    }

    /// delist_card: Remove an escrowed Card and return to its owner.
    /// - Market must be active; caller must match Card.owner.
    public entry fun delist_card(
        cid:    ID,
        market: &mut Marketplace,
        ctx:    &mut TxContext
    ) {
        assert!(!market.frozen, E_MARKET_FROZEN);
        let caller = tx_context::sender(ctx);

        let mut card = remove_listing(market, cid);
        assert!(card.owner == caller, E_NOT_OWNER);

        card.for_sale = false;
        card.price    = 0;
        transfer::public_transfer(card, caller);
    }

    /// buy_card: Purchase an escrowed Card NFT.
    /// - Market must be active; buyer must send ≥ price.
    /// - Splits payment into fee & seller proceeds.
    /// - Updates `total_vol`, emits `CardPurchased`, and transfers NFT.
    public entry fun buy_card(
        cid:     ID,
        mut payment: Coin<SUI>,
        market:  &mut Marketplace,
        ctx:     &mut TxContext
    ) {
        assert!(!market.frozen, E_MARKET_FROZEN);
        let buyer = tx_context::sender(ctx);

        let mut card = remove_listing(market, cid);
        assert!(card.for_sale, E_NOT_FOR_SALE);

        let price  = card.price;
        let seller = card.owner;
        let ptype  = card.pokemon_type;
        assert!(coin::value(&payment) >= price, E_INSUFFICIENT_PAYMENT);

        let fee      = (price * market.fee_bps) / 10_000;
        let fee_coin = coin::split(&mut payment, fee, ctx);
        transfer::public_transfer(fee_coin, market.fee_dest);
        transfer::public_transfer(payment, seller);

        market.total_vol = market.total_vol + price;
        event::emit(CardPurchased {
            card_id:      cid,
            seller,
            buyer,
            price,
            fee,
            pokemon_type: ptype
        });

        card.owner    = buyer;
        card.for_sale = false;
        card.price    = 0;
        transfer::public_transfer(card, buyer);
    }

    /// get_listings: Return a vector of IDs for all current listings.
    public fun get_listings(market: &Marketplace): vector<ID> {
        let mut ids = vector::empty<ID>();
        let len     = vector::length(&market.listings);
        let mut i   = 0;
        while (i < len) {
            let c_ref = vector::borrow(&market.listings, i);
            vector::push_back(&mut ids, object::id(c_ref));
            i = i + 1;
        };
        ids
    }

    // -------------------------------------------------------------------------
    // Administrative Functions
    // -------------------------------------------------------------------------

    /// update_fee: Change marketplace fee settings (admin only).
    /// - Ensures new fee ≤ 1000 basis points (10%).
    public entry fun update_fee(
        _cap:     &AdminCap,
        market:   &mut Marketplace,
        new_fee:  u64,
        new_dest: address
    ) {
        assert!(new_fee <= 1000, E_INVALID_METADATA);
        market.fee_bps  = new_fee;
        market.fee_dest = new_dest;
    }

    /// toggle_freeze: Pause or resume all mint/list/buy/delist ops (admin only).
    public entry fun toggle_freeze(
        _cap:    &AdminCap,
        market:  &mut Marketplace
    ) {
        market.frozen = !market.frozen;
    }
}
