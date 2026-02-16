#[test_only]
module Escrow::escrow_tests {
    use Escrow::escrow;

    const BUYER: address = @0x1;
    const SELLER: address = @0x2;

    // позитив: deposit → fund → release
    #[test]
    public entry fun test_happy_flow() {
        let bw = escrow::new_wallet();
        let sw = escrow::new_wallet();

        escrow::deposit(&mut bw, 150);
        let d = escrow::create(BUYER, SELLER, 100);

        escrow::fund(BUYER, &mut bw, &mut d);
        escrow::release(SELLER, &mut sw, &mut d);

        assert!(escrow::balance(&bw) == 50, 0);
        assert!(escrow::balance(&sw) == 100, 1);

        // потребляем ресурсы
        escrow::destroy_deal_for_test(d);
        escrow::destroy_wallet_for_test(bw);
        escrow::destroy_wallet_for_test(sw);
    }

    // негатив: refund после fund (деньги возвращаются покупателю)
    #[test]
    public entry fun test_refund_flow() {
        let bw = escrow::new_wallet();
        let sw = escrow::new_wallet();

        escrow::deposit(&mut bw, 100);
        let d = escrow::create(BUYER, SELLER, 100);

        escrow::fund(BUYER, &mut bw, &mut d);
        escrow::refund(BUYER, &mut bw, &mut d);

        assert!(escrow::balance(&bw) == 100, 0);
        assert!(escrow::balance(&sw) == 0, 1);

        escrow::destroy_deal_for_test(d);
        escrow::destroy_wallet_for_test(bw);
        escrow::destroy_wallet_for_test(sw);
    }
}
