// test_link_call
//# publish
module 0x42::ReceiverStyleCall2 {

    struct S has drop { x: u64 }

    fun plus_one(self: &mut S): S {
        self.x = self.x + 1;
        S { x: self.x }
    }

    fun plus_two(self: &mut S): S {
        self.x = self.x + 2;
        S { x: self.x }
    }

    fun plus_three(self: &mut S): S {
        self.x = self.x + 3;
        S { x: self.x }
    }

    fun test_link_call(s: S) {
        let p1m = &mut s;
        let p2m = p1m.plus_one().plus_two().plus_three().plus_one().plus_two().plus_three().plus_one().plus_two().plus_three().plus_one().plus_two().plus_three();
    }
}

//# run 0x42::ReceiverStyleCall2::test
