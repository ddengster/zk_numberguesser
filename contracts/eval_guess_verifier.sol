// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;

import "./verifier_common.sol";

contract EvalGuessVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x28f83928f26a1479b827fa032aeb415466f6d9679897fec4872618d5416c723d), uint256(0x13983b60d9a9d3c4efc36b8e250e2b4f9f4c3cf166382c617b7008139e62bf67));
        vk.beta = Pairing.G2Point([uint256(0x02e96869baa3df1569d98af3924ad7da1fcdeb5db3431acbd21ee0d58b484521), uint256(0x17af7d6f985b7b0f71c5a4d4bd9ca9223b5dd1992ec4799fae6bf9db3d9af211)], [uint256(0x04b9767f7ee367b2bd191c93ca0376ae8ae1ac51072bf175f9cbd061f577be0c), uint256(0x14ae181e3077833183d2c1a5394102f4b27bb11ef617ce3d1880c187b38dcf35)]);
        vk.gamma = Pairing.G2Point([uint256(0x0a9f5131ee3977324ecf812acbddedf49cc43e0ec372865364de9bb68d25e3e4), uint256(0x12ab7fa8a4b1f02a9483e3909d43764fa47fe04615a909e75f5e6e70babac5d6)], [uint256(0x08edb2db2c5f20b8592f3d749f773902be6317c003ac7c80768152f39f3f1da4), uint256(0x220d0527d9089226a04307c7cd2f1a153d7815becbade6244a04e0fed7653942)]);
        vk.delta = Pairing.G2Point([uint256(0x150771f43c5d8b4a3b26411b7cc80409d54c5d1706208eefe7f3c08ec0554ac0), uint256(0x0d7523faf88b0b09f30e47448c582402951c00935ce4e0f57d1648d2fd9af6f9)], [uint256(0x1ce6fdd7793ff020c468e8f0af7498fe58f1a7d20892dd40a71f40de1d7d4719), uint256(0x0ab86d4a881f67318565a2ef519d6e7a9ba130f7bdd8c774a574001002b55eaa)]);
        vk.gamma_abc = new Pairing.G1Point[](4);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x3041f6b9b6d1071d12bd975b27ef32fdad5aacd391a29526e8b6f4a76d7787ad), uint256(0x237de92ee1640570887af1e7d592cb6ffba94195a672ee53c5918cb201066e12));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x23b66159331eb0b51a42ed367fbb130b510d2508f859778a2347ac042a063147), uint256(0x2f8d44ec8ce8c2ec3ef8f663ca1091a31759d257021c62ed4bc121fd01bd8d67));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0524409ee23e102c835759e30506f4e4bcd2d5b82164f423e83f3c0a5703fed6), uint256(0x06c108822a313e9e9b2253ea4b645d7c197c9a6f6b33e7714c9fd1ada005d15f));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1d8e2935fb541740b07e13bfa917191a3b6c34c0b36765aca295e9e1ac907dc4), uint256(0x28e7865944fade8abe24925f8341e9a6138136cc9493185c223d02178f49a930));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[3] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](3);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
