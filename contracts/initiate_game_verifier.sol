// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;

import "./verifier_common.sol";

contract InitiateGameVerifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x2572cdcbc2c4263037382bb2c37c3c9c138494ad0236284c182b90effa2e4c7f), uint256(0x1dfb68474fe02b51d4844c09f1c5d1890b06b7f8ccaa46cedc13220293307888));
        vk.beta = Pairing.G2Point([uint256(0x1104e6145ae3e523eff873b5379179f7b42efc6106e9ecbd19d40fd5a87d9e48), uint256(0x2b62b8a1b8d509da304cab9012146b90c06f0195363f883a17c936d9427734d9)], [uint256(0x249ef2772ecc435ba179bb2d0d18da79fb1d26ae8a17106cb5ecf9efb1d53417), uint256(0x0d58adf0cda61911fdcaf2c00e2e13fbacbbc922ec09733955efdf5d04ca254b)]);
        vk.gamma = Pairing.G2Point([uint256(0x1942db75794e738c41770a93ab4a34687beeafd19a59852ddb397e844e301b44), uint256(0x2501ffe05f0415a88538304a3e2b6f226458ad7c76012916b13c952d45f1325a)], [uint256(0x2d06ee05aa8da45e78289e643e00e65d8e5053fcf6a218015f782458d38a1bb4), uint256(0x20baa86824c9d49a60555b6ea54bfeb0810700d091c9cb58f29f62b8de404be2)]);
        vk.delta = Pairing.G2Point([uint256(0x25a74814a7265c94cd83d59bcdb8858f4e19b09eee3492b207f7c50917105466), uint256(0x0c63e24d0ad5a7f3f1e44b99deff920262bf7bfc7ebb8c28c12b68321d595748)], [uint256(0x07a6585b06c811125bde2b7e3d8ca271d9905294803c9d05f8e413a6184846b4), uint256(0x1b9e2e87bcc30567c14c11a9b0e0a3d1dbc724cd876c9701377f676ed3778c0c)]);
        vk.gamma_abc = new Pairing.G1Point[](5);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0a765d76d1747945109736a7e883a7e43c696648e1ffe4692bf5c7b7e34dc281), uint256(0x139843cd275cd968901bfc3e1c17c6e89a894a673d45da3b6c73e1ee7726b966));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x232dada0021f8b423da0a98ac8ad1a9cbef08c7633595afbcd152b5e8b2e7de7), uint256(0x0e0da6a66de9a9e4871636ac03e9cdfb3be81f8a55ce650826a0a4b14a4d368b));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x1e809ee108f1ed0cbc7a6e13c61f239aac6f2ced68de91be6d496b1827b5f9a9), uint256(0x25fdc617fe7d536695211fbb863df14288337e9536d61cb3f20296d4f94c63ff));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2245da2fe02985aecd7f9f5000c7ffc639dc1cdd2999df96f98598eb43ef0787), uint256(0x06096cec92f7658c5cd5d8cef9556ca2d4d449ee5f0b693d941803f7bd6b030f));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x109089defedfd08bf3b850ba91b06d40a7231c1ad4cfdd611505d8f76304d46e), uint256(0x1ad8b250fc02bd915b917e6fed9259d6eaf63bd52e55ddd7f846c85ed4a152d3));
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
            Proof memory proof, uint[4] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](4);
        
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
